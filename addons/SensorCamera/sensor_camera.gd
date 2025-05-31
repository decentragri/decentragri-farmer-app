extends Node

var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "SensorCamera"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("SensorCamera plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No SensorCamera plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.on_sensor_data_received.connect(_on_sensor_data_received)
	
	
func _on_sensor_data_received(_data: Variant) -> void:
	print(_data)


func start_scanner() -> void:
	if android_plugin:
		android_plugin.startScanner()
