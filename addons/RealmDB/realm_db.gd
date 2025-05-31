extends Node

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
		else:
			printerr("No RealmDB plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.on_data_saved.connect(_on_data_saved)
	android_plugin.on_data_loaded.connect(_on_data_loaded)
	
	
func _on_data_saved() -> void:
	realm_db_data_saved.emit()
	
	
func _on_data_loaded(data: String) -> void:
	var parsed_data: Dictionary = JSON.parse_string(data)
	if parsed_data != null:
		realm_db_data_loaded.emit(parsed_data)
	else:
		realm_db_data_loaded.emit({"eror": "Unknown error encountered"})


func start_biometrics_auth() -> void:
	if android_plugin:
		android_plugin.startAuthentication()
		
		
func clear_pending_data() -> void:
	if android_plugin:
		android_plugin.clearPendingData()


func load_all_sensor_data() -> void:
	if android_plugin:
		android_plugin.loadAllSensorData()
