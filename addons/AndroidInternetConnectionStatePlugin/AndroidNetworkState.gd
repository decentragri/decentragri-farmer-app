extends Node
class_name AndroidNetworkState

signal stateChanged(curState: bool)

const _pluginName = "AndroidInternetConnectionStatePlugin"
var android_plugin: Object

var has_network: bool
var sync_queue: Array = []


func _ready() -> void:
	var plugin_name: String = "AndroidInternetConnectionStatePlugin"
	
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("AndroidInternetConnectionStatePlugin token plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No AndroidInternetConnectionStatePlugin found!")
	
	
func connect_signals() -> void:
	android_plugin.stateChanged.connect(func(state: String) -> void:
		stateChanged.emit(state == "true")
		_on_network_state_changed(state == "true"))
	NetworkState.stateChanged.connect(_on_network_state_changed)
	Scan.save_soil_meter_scan_complete.connect(_on_save_soil_scan_meter_complete)
	
	
func _on_network_state_changed(network: bool) -> void:
	has_network = network
	if has_network:
		print("Network is back, attempting to sync pending RealmDB data...")
		_sync_pending_data()
	
	
func hasNetwork() -> bool:
	if android_plugin:
		return bool(android_plugin.isNetworkConnected())
	return false
	
	
func _sync_pending_data() -> void:
	if not hasNetwork():
		return
	if not RealmDB:
		printerr("RealmDB singleton not found")
		return

	RealmDB.load_all_sensor_data()
	RealmDB.realm_db_data_loaded.connect(_on_pending_data_loaded, CONNECT_ONE_SHOT)
	
	
func _on_pending_data_loaded(data: Dictionary) -> void:
	if data.has("pending"):
		var pending_entries: Array = data["pending"]
		for entry: Dictionary in pending_entries:
			print("Syncing:", entry)
			if entry.has("fertility") and entry.has("moisture"):
				var id = entry.get("id", "")
				if id != "":
					sync_queue.append(id)
				Scan.save_soil_meter_scan(entry)
	
	
func _on_save_soil_scan_meter_complete(message: Dictionary) -> void:
	if message.has("error"):
		print("Scan sync failed, will retry on next network event")
		return

	# Match completed sync by ID using known queue (message contains original data)
	if message.has("success"):
		
		#TODO RETURN ID property and value from serverf on get_soil_scan_meter_complete
		var synced_id: String = message["success"]["id"]
		if sync_queue.has(synced_id):
			RealmDB.mark_data_as_synced(synced_id)
			sync_queue.erase(synced_id)
			print("Scan synced and marked as synced in RealmDB")

	# If all queued items were processed, clear synced ones
	if sync_queue.is_empty():
		RealmDB.clear_pending_data()
