extends Node

signal gps_coordinates_received(data: String)

var android_plugin: Object
var _current_token: String
var _retry_count: int = 0
const MAX_RETRY_COUNT: int = 3     # You can change this number depending on how many times you want to retry.


func _ready() -> void:
	var plugin_name: String = "Firebase"
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("Firebase plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No Firebase plugin found!")


func connect_signals() -> void:
	android_plugin.fcm_token_received.connect(_on_fcm_token_received)
	Auth.save_fcm_token_complete.connect(_on_save_fcm_token_complete)


func _on_fcm_token_received(token: String) -> void:
	if token == "":
		print("Token retrieval failed.")
	else:
		print("Got Firebase token: ", token)
		_current_token = token
		_retry_count = 0  # reset retry counter whenever a new token is received
		Auth.save_fcm_token(token)


func _on_save_fcm_token_complete(message: Dictionary) -> void:
	if message.has("error"):
		printerr("Saving token failed with error: ", message["error"])
		if _retry_count < MAX_RETRY_COUNT:
			_retry_count += 1
			print("Retrying to save token (attempt ", _retry_count, ")...")
			Auth.save_fcm_token(_current_token)
		else:
			printerr("Max retry attempts reached, token saving stopped.")
	else:
		print("Token successfully saved!")
		_retry_count = 0 # reset retry count on success
