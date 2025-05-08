extends Node


var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "GPSLocator"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("GPS Locator plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
			OS.request_permissions()
		else:
			printerr("No GPS Locator plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.on_gps_coordinates_received.connect(_on_gps_coordinates_received)
	
	
func _on_gps_coordinates_received(_data: String) -> void:
	print(_data)


func start_gps() -> String:
	if android_plugin:
		return android_plugin.requestGPSCoordinates() as String
	return ""
