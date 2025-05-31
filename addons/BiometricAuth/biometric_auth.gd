extends Node

signal bio_auth_success
signal bio_auth_failed


var android_plugin: Object

func _ready() -> void:
	var plugin_name: String = "BiometricAuth"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("BiometricAuth  plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No BiometricAuth plugin found!")
	
	
func connect_signals() -> void:
	android_plugin.on_auth_success.connect(_on_auth_success)
	android_plugin.on_auth_failed.connect(_on_auth_failed)
	
	
func _on_auth_success() -> void:
	bio_auth_success.emit()
	
	
func _on_auth_failed(message: String) -> void:
	bio_auth_failed.emit(message)
	
	
func start_biometrics_auth() -> void:
	if android_plugin:
		android_plugin.startAuthentication()
		
		
