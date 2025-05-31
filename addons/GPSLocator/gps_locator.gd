extends Node

signal gps_coordinates_received(data: String)


var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "GPSLocator"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("GPS Locator plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No GPS Locator plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.on_gps_coordinates_received.connect(_on_gps_coordinates_received)
	
	
func _on_gps_coordinates_received(data: String) -> void:
	print("hey: ", data)
	gps_coordinates_received.emit(data)
	
	
func start_gps():
	if android_plugin:
		android_plugin.requestGPSCoordinates()
