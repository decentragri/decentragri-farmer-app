extends Node

# Signals
signal realm_db_data_saved
signal realm_db_data_loaded(data: String)

var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "RealmDB"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("RealmDB plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
			# Initialize Realm when the node is ready
			init_realm()
		else:
			printerr("No RealmDB plugin found!")

func connect_signals() -> void:
	if android_plugin:
		if android_plugin.has_signal("on_data_saved"):
			android_plugin.on_data_saved.connect(_on_data_saved)
		if android_plugin.has_signal("on_data_loaded"):
			android_plugin.on_data_loaded.connect(_on_data_loaded)

func _on_data_saved() -> void:
	realm_db_data_saved.emit()

func _on_data_loaded(data: String) -> void:
	realm_db_data_loaded.emit(data)

# Initialize the Realm database
func init_realm() -> void:
	if android_plugin:
		android_plugin.initRealm()

# Save sensor data to Realm
func save_sensor_data(id: String, json_data: String) -> void:
	if android_plugin:
		android_plugin.saveSensorData(id, json_data)

# Load all sensor data from Realm
func load_all_sensor_data() -> void:
	if android_plugin:
		android_plugin.loadAllSensorData()

# Mark data as synced
func mark_data_as_synced(id: String) -> void:
	if android_plugin:
		android_plugin.markDataAsSynced(id)

# Clear all synced data
func clear_synced_data() -> void:
	if android_plugin:
		android_plugin.clearSyncedData()

# Clear pending data (synced data)
func clear_pending_data() -> void:
	if android_plugin:
		android_plugin.clearPendingData()

# Save data with origin information
func save_data(data: String, origin: String = "") -> void:
	if android_plugin and not data.is_empty():
		var id = str(Time.get_unix_time_from_system()) + "_" + origin
		save_sensor_data(id, data)
		_handle_origin_signal(origin)

# Handle origin-specific signals after saving
func _handle_origin_signal(origin: String) -> void:
	var response: Dictionary[String, String] = {
		"status": "success",
		"message": "Data saved locally",
		"origin": origin
	}
	
	match origin:
		"PlantHealthScan":
			if Scan and Scan.has_signal("save_plant_scan_complete"):
				Scan.save_plant_scan_complete.emit(response)
		"SoilAnalysisScan":
			if Scan and Scan.has_signal("save_soil_meter_scan_complete"):
				Scan.save_soil_meter_scan_complete.emit(response)
