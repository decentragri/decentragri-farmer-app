extends Node
class_name AndroidNetworkState

signal stateChanged(curState: bool)
signal realm_db_data_loaded(data: String)
signal sync_completed(success: bool, message: String)
signal sync_progress(current: int, total: int, message: String)

const PLUGIN_NAME: String = "AndroidInternetConnectionStatePlugin"
const MAX_RETRY_ATTEMPTS: int = 3
const INITIAL_RETRY_DELAY: float = 2.0  # seconds
const MAX_RETRY_DELAY: float = 60.0  # 1 minute max delay

var android_plugin: Object = Engine.get_singleton(PLUGIN_NAME)
var has_network: bool = false
var sync_queue: Array[String] = []
var failed_syncs: Dictionary[String, Variant] = {}  # Dictionary[String, Dictionary] - entry_id: {attempts: int, last_error: String, next_retry: float}
var is_syncing: bool = false
var current_sync_operations: int = 0
var total_sync_operations: int = 0

func _ready() -> void:
	print("AndroidInternetConnectionStatePlugin loaded")
	connect_signals()
	has_network = hasNetwork()

func connect_signals() -> void:
	android_plugin.stateChanged.connect(_on_android_state_changed)
	NetworkState.stateChanged.connect(_on_network_state_changed)
	Scan.save_soil_meter_scan_complete.connect(_on_scan_sync_complete)
	Scan.save_plant_scan_complete.connect(_on_scan_sync_complete)

func _on_android_state_changed(state: String) -> void:
	var is_connected = state == "true"
	stateChanged.emit(is_connected)
	_on_network_state_changed(is_connected)

func _on_network_state_changed(network: bool) -> void:
	var was_online = has_network
	has_network = network
	
	if has_network and not was_online:
		print("Network is back, syncing pending data...")
		_sync_pending_data()
	elif not has_network and was_online:
		print("Network connection lost")

func hasNetwork() -> bool:
	return bool(android_plugin.isNetworkConnected())

func _sync_pending_data(force: bool = false) -> void:
	if is_syncing and not force:
		print("Sync already in progress")
		return
		
	if not hasNetwork():
		print("No network available, skipping sync")
		sync_completed.emit(false, "No network available")
		return

	is_syncing = true
	current_sync_operations = 0
	total_sync_operations = 0
	print("Starting sync of pending data...")
	sync_progress.emit(0, 0, "Starting sync...")
	
	# Process any previously failed syncs first
	_process_failed_syncs()
	
	# Disconnect any existing connections to prevent duplicates
	if RealmDB.realm_db_data_loaded.is_connected(_on_pending_data_loaded):
		RealmDB.realm_db_data_loaded.disconnect(_on_pending_data_loaded)
		
	# Connect with one-shot to ensure we don't process the same data multiple times
	RealmDB.realm_db_data_loaded.connect(_on_pending_data_loaded, CONNECT_ONE_SHOT)
	RealmDB.load_all_sensor_data()

func _process_failed_syncs() -> void:
	var now: float = Time.get_unix_time_from_system()
	var retry_count: int = 0
	
	for entry_id: String in failed_syncs.duplicate():
		var entry: Dictionary = failed_syncs[entry_id] as Dictionary
		if entry.next_retry <= now:
			if entry.attempts >= MAX_RETRY_ATTEMPTS:
				print("Max retry attempts reached for entry: ", entry_id)
				sync_progress.emit(-1, -1, "Failed to sync some items after %d attempts" % MAX_RETRY_ATTEMPTS)
				failed_syncs.erase(entry_id)
			else:
				retry_count += 1
				# This will be processed in the normal sync flow
				sync_queue.append(entry_id)
	
	if retry_count > 0:
		print("Retrying ", retry_count, " previously failed syncs")

func _on_pending_data_loaded(data: String) -> void:
	is_syncing = false
	
	var pending_data: Array = _parse_pending_data(data)
	if pending_data.is_empty():
		return
	
	print("Processing ", pending_data.size(), " pending entries...")
	await _process_pending_entries(pending_data)

func _parse_pending_data(data: String) -> Array:
	if data.is_empty():
		print("No pending data to sync")
		return []
	
	var json: JSON = JSON.new()
	var error: int = json.parse(data)
	
	if error != OK:
		printerr("Failed to parse pending data: ", json.get_error_message())
		return []
	
	if not json.data is Array:
		printerr("Unexpected data format from RealmDB. Expected array, got: ", typeof(json.data))
		return []
	
	return json.data as Array


func _process_pending_entries(entries: Array) -> void:
	total_sync_operations = entries.size()
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
			
		var entry_id: String = _get_entry_id(entry)
		if entry_id.is_empty():
			continue
		
		sync_queue.append(entry_id)
		await _process_single_entry(entry_id, entry as Dictionary)


func _get_entry_id(entry: Dictionary) -> String:
	var entry_id: String = str(entry.get("id", "")).strip_edges()
	if entry_id.is_empty():
		printerr("Entry missing ID, skipping")
	return entry_id


func _process_single_entry(entry_id: String, entry: Dictionary) -> void:
	current_sync_operations += 1
	sync_progress.emit(current_sync_operations, total_sync_operations, "Syncing item %d of %d" % [current_sync_operations, total_sync_operations])
	
	var success: bool = false
	var error_message: String = ""
	
	if _is_soil_meter_scan(entry):
		success = await _sync_with_retry(entry_id, entry, "_sync_soil_meter_scan")
		if not success:
			error_message = "Failed to sync soil meter scan"
	elif _is_plant_health_scan(entry):
		success = await _sync_with_retry(entry_id, entry, "_sync_plant_health_scan")
		if not success:
			error_message = "Failed to sync plant health scan"
	else:
		error_message = "Unknown scan type"
		success = false
	
	if success:
		# Remove from failed syncs if it was there
		failed_syncs.erase(entry_id)
		# Mark as synced in the database
		RealmDB.mark_data_as_synced(entry_id)
		sync_queue.erase(entry_id)
	else:
		printerr("Failed to sync entry ", entry_id, ": ", error_message)
		_handle_sync_failure(entry_id, error_message)
	
	# Check if this was the last operation
	if sync_queue.is_empty() and current_sync_operations >= total_sync_operations:
		_sync_completed()


func _sync_with_retry(entry_id: String, entry_data: Dictionary, sync_func: String) -> bool:
	var attempts: int = 0
	var delay: float = INITIAL_RETRY_DELAY
	var last_error: String = ""
	
	while attempts < MAX_RETRY_ATTEMPTS:
		var success: bool = false
		var error_message: String = ""
		
		# Call the appropriate sync function
		if sync_func == "_sync_soil_meter_scan":
			var result: Dictionary = await _sync_soil_meter_scan_with_error_handling(entry_id, entry_data)
			success = result.get("success", false)
			error_message = result.get("error", "")
		else:
			var result: Dictionary = await _sync_plant_health_scan_with_error_handling(entry_id, entry_data)
			success = result.get("success", false)
			error_message = result.get("error", "")
		
		if success:
			return true
			
		# If we get here, there was an error
		attempts += 1
		last_error = error_message if not error_message.is_empty() else "Unknown error"
		printerr("Sync attempt ", attempts, " failed for ", entry_id, ": ", last_error)
		
		if attempts < MAX_RETRY_ATTEMPTS:
			var next_retry: float = Time.get_unix_time_from_system() + delay
			_update_failed_sync(entry_id, attempts, last_error, next_retry)
			
			# Wait with exponential backoff
			var timer: SceneTreeTimer = get_tree().create_timer(delay)
			await timer.timeout
			delay = min(delay * 2, MAX_RETRY_DELAY)  # Exponential backoff with max limit
	
	# If we get here, all retries failed
	var next_retry = Time.get_unix_time_from_system() + delay
	_update_failed_sync(entry_id, attempts, last_error, next_retry)
	return false

func _update_failed_sync(entry_id: String, attempts: int, error: String, next_retry: float) -> void:
	if not entry_id in failed_syncs:
		failed_syncs[entry_id] = {
			"attempts": 0,
			"last_error": "",
			"next_retry": 0.0
		}
	
	var entry: Dictionary = failed_syncs[entry_id] as Dictionary
	entry.attempts = attempts
	entry.last_error = error
	entry.next_retry = next_retry

func _handle_sync_failure(entry_id: String, error_message: String) -> void:
	var now: float = Time.get_unix_time_from_system()
	var delay: float = min(INITIAL_RETRY_DELAY * pow(2, failed_syncs.get(entry_id, {"attempts": 0}).attempts), MAX_RETRY_DELAY)
	
	if not entry_id in failed_syncs:
		failed_syncs[entry_id] = {
			"attempts": 0,
			"last_error": "",
			"next_retry": 0.0
		}
	
	var entry: Dictionary = failed_syncs[entry_id] as Dictionary
	entry.attempts += 1
	entry.last_error = error_message
	entry.next_retry = now + delay
	
	if entry.attempts >= MAX_RETRY_ATTEMPTS:
		sync_progress.emit(-1, -1, "Max retry attempts reached for an item")
		# Optionally: Notify user about the failure
		# _notify_sync_failure(entry_id, error_message)

func _sync_completed() -> void:
	var success: bool = failed_syncs.is_empty()
	var message: String = "Sync completed successfully" if success else "Sync completed with some failures"
	
	print(message)
	sync_completed.emit(success, message)
	is_syncing = false
	
	# Clear synced data if everything was successful
	if success:
		RealmDB.clear_synced_data()
	else:
		# Schedule next retry for failed items
		var next_retry_time: float = INF
		for entry_id: String in failed_syncs:
			next_retry_time = min(next_retry_time, (failed_syncs[entry_id] as Dictionary).get("next_retry", INF))
		
		if next_retry_time != INF:
			var time_until_retry: float = next_retry_time - Time.get_unix_time_from_system()
			if time_until_retry > 0:
				var timer: SceneTreeTimer = get_tree().create_timer(time_until_retry)
				timer.timeout.connect(_on_retry_timeout)

func _on_retry_timeout() -> void:
	if hasNetwork() and not is_syncing:
		_sync_pending_data(true)  # Force sync


func _is_soil_meter_scan(entry: Dictionary) -> bool:
	return entry.has("fertility") and entry.has("moisture")


func _is_plant_health_scan(entry: Dictionary) -> bool:
	return entry.has("imageBytes") and entry.has("cropType")


func _sync_soil_meter_scan(entry_id: String, entry_data: Dictionary) -> void:
	print("Syncing soil meter data (ID: %s)" % entry_id)
	Scan.save_soil_meter_scan(entry_data)
	var result: Variant = await Scan.save_soil_meter_scan_complete
	_handle_scan_result(entry_id, result)

# Wrapper with error handling for soil meter scan
func _sync_soil_meter_scan_with_error_handling(entry_id: String, entry_data: Dictionary) -> Dictionary:
	var result: Dictionary[String, Variant] = {"success": false}
	
	if not hasNetwork():
		result["error"] = "No network connection"
		return result

	# In GDScript, we'll use a flag to track success/failure
	var success: bool = false
	var error_message: String = ""
	
	# Make the API call
	Scan.save_soil_meter_scan(entry_data)
	var response: Variant = await Scan.save_soil_meter_scan_complete
	
	# Check the response
	if response is Dictionary and response.has("error"):
		error_message = str(response.error)
	else:
		success = true
	
	result["success"] = success
	if not success and not error_message.is_empty():
		result["error"] = error_message
		
	return result

func _sync_plant_health_scan(entry_id: String, entry_data: Dictionary) -> void:
	print("Syncing plant health scan data (ID: %s)" % entry_id)
	Scan.save_plant_scan(entry_data)
	var result: Variant = await Scan.save_plant_scan_complete
	_handle_scan_result(entry_id, result)

# Wrapper with error handling for plant health scan
func _sync_plant_health_scan_with_error_handling(entry_id: String, entry_data: Dictionary) -> Dictionary:
	var result: Dictionary = {"success": false}
	
	if not hasNetwork():
		result["error"] = "No network connection"
		return result

	# In GDScript, we'll use a flag to track success/failure
	var success: bool = false
	var error_message: String = ""
	
	# Make the API call
	Scan.save_plant_scan(entry_data)
	var response: Variant = await Scan.save_plant_scan_complete
	
	# Check the response
	if response is Dictionary and response.has("error"):
		error_message = str(response.error)
	else:
		success = true
	
	result["success"] = success
	if not success and not error_message.is_empty():
		result["error"] = error_message
		
	return result


func _handle_scan_result(entry_id: String, result: Variant) -> void:
	if result is Dictionary and result.has("error"):
		printerr("Failed to sync entry ", entry_id, ": ", result["error"])
		return


func _on_scan_sync_complete(message: Dictionary) -> void:
	# This function is kept for backward compatibility
	# The actual handling is now done in _process_single_entry and related functions
	pass
