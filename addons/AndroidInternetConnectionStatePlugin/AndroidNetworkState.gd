extends Node
class_name AndroidNetworkState

signal stateChanged(curState: bool)
signal realm_db_data_loaded(data: String)

const PLUGIN_NAME = "AndroidInternetConnectionStatePlugin"

var android_plugin = Engine.get_singleton(PLUGIN_NAME)
var has_network: bool = false
var sync_queue: Array[String] = []
var is_syncing: bool = false

func _ready() -> void:
	print("AndroidInternetConnectionStatePlugin loaded")
	connect_signals()
	has_network = hasNetwork()

func connect_signals() -> void:
	android_plugin.stateChanged.connect(_on_android_state_changed)
	NetworkState.stateChanged.connect(_on_network_state_changed)
	Scan.save_soil_meter_scan_complete.connect(_on_save_soil_scan_meter_complete)

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

func _sync_pending_data() -> void:
	if is_syncing:
		print("Sync already in progress")
		return
		
	if not hasNetwork():
		print("No network available, skipping sync")
		return

	is_syncing = true
	print("Starting sync of pending data...")
	
	# Disconnect any existing connections to prevent duplicates
	if RealmDB.realm_db_data_loaded.is_connected(_on_pending_data_loaded):
		RealmDB.realm_db_data_loaded.disconnect(_on_pending_data_loaded)
		
	# Connect with one-shot to ensure we don't process the same data multiple times
	RealmDB.realm_db_data_loaded.connect(_on_pending_data_loaded, CONNECT_ONE_SHOT)
	RealmDB.load_all_sensor_data()

func _on_pending_data_loaded(data: String) -> void:
	is_syncing = false
	
	if data.is_empty():
		print("No pending data to sync")
		return
	
	var json = JSON.new()
	var error = json.parse(data)
	
	if error != OK:
		printerr("Failed to parse pending data: ", json.get_error_message())
		return
	
	if not json.data is Array:
		printerr("Unexpected data format from RealmDB. Expected array, got: ", typeof(json.data))
		return
	
	var pending_data: Array = json.data
	print("Processing ", pending_data.size(), " pending entries...")
	
	for entry in pending_data:
		if not entry is Dictionary:
			continue
			
		var entry_id = str(entry.get("id", "")).strip_edges()
		if entry_id.is_empty():
			printerr("Entry missing ID, skipping")
			continue
		
		sync_queue.append(entry_id)
		
		if entry.has("fertility") and entry.has("moisture"):
			print("Syncing soil meter data (ID: %s)" % entry_id)
			Scan.save_soil_meter_scan(entry)
			var result = await Scan.save_soil_meter_scan_complete
			if result is Dictionary and result.has("error"):
				printerr("Failed to sync entry ", entry_id, ": ", result["error"])
				break

func _on_save_soil_scan_meter_complete(message: Dictionary) -> void:
	if message.has("error"):
		var error_msg = message.get("error", "Unknown error")
		printerr("Scan sync failed: ", error_msg)
		return

	if not message.has("success"):
		printerr("Invalid response format: missing success field")
		return

	var success_data = message["success"]
	if not success_data is Dictionary:
		success_data = {"id": str(success_data)}

	var synced_id = str(success_data.get("id", "")).strip_edges()
	if synced_id.is_empty():
		printerr("Missing or invalid ID in success response")
		return

	if sync_queue.has(synced_id):
		print("Marking data as synced in RealmDB, ID:", synced_id)
		RealmDB.mark_data_as_synced(synced_id)
		sync_queue.erase(synced_id)
		print("Successfully synced and marked data in RealmDB")

		if sync_queue.is_empty():
			print("All pending data synced, cleaning up...")
			RealmDB.clear_synced_data()
	else:
		print("Received sync confirmation for unknown ID: ", synced_id)
