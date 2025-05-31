extends Node

signal image_request_completed(buffer: String)
signal image_request_failed(message: String)


var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "GodotGetImage"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("GodotGetImage plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
			set_options()
		else:
			printerr("No GodotGetImage plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.image_request_completed.connect(_on_image_request_completed)
	
	
func _on_image_request_completed(data: Dictionary) -> void:
	image_request_completed.emit(data)
	
	
func _on_image_request_failed(data: String) -> void:
	image_request_failed.emit(data)
	
	
func get_camera_image() -> void:
	if android_plugin:
		android_plugin.getCameraImage()
		

func get_gallery_image() -> void:
	if android_plugin:
		android_plugin.getGalleryImage()


func set_options(options_set: Dictionary[String, Variant] = {}) -> void:
	if android_plugin:
		options_set = {
		"image_height" :650,
		"image_width" : 650,
		"quality": 100,
		"image_format" : "png"
	}
	android_plugin.setOptions(options_set)
