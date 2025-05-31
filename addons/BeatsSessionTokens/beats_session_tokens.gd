extends Node

signal jwt_retrieve_completed(jwt: Dictionary)

var android_plugin: Object


func _ready() -> void:
	var plugin_name: String = "BeatsSessionTokens"
	
	if not android_plugin:
		if Engine.has_singleton(plugin_name):
			print("Beats session token plugin found!")
			android_plugin = Engine.get_singleton(plugin_name)
			connect_signals()
		else:
			printerr("No plugin found!")
	

func connect_signals() -> void:
	if android_plugin:
		android_plugin.connect("jwt_stored", Callable(self, "jwt_stored_completed"))
		android_plugin.connect("jwt_retrieved", Callable(self, "jwt_retrieved_completed"))
		android_plugin.connect("jwt_cleared", Callable(self, "jwt_cleared_completed"))
	else:
		printerr("Plugin not initialized, cannot connect signals!")
	
	
func jwt_stored_completed(message: String) -> void:
	print("Stored: ", message)
	
	
func jwt_retrieved_completed(message: Variant) -> void:
	print("Retrieved: ", message)
	if message is String:
		var jwt_tokens: Variant = JSON.parse_string(message)
		jwt_retrieve_completed.emit(jwt_tokens)
		print("Parsed JWT tokens: ", jwt_tokens)
	
	
func jwt_cleared_completed(message: String) -> void:
	print("Cleared: ", message)
	
	
func store_jwt_tokens(jwt_tokens: Dictionary) -> void:
	# Check that all the required keys are present
	if not jwt_tokens.has("access_token") or not jwt_tokens.has("refresh_token") or not jwt_tokens.has("login_type"):
		printerr("Error: Missing required keys in JWT data")
		return
	
	# Call the plugin method
	if android_plugin:
		android_plugin.storeJwt(jwt_tokens.access_token, jwt_tokens.refresh_token, jwt_tokens.login_type)
	else:
		printerr("Plugin not initialized!")

func retrieve_jwt_tokens() -> void:
	# Retrieve the JWT data (async)
	if android_plugin:
		android_plugin.retrieveJwt()
	else:
		printerr("Plugin not initialized!")

func clear_jwt_tokens() -> void:
	# Clear JWT data
	if android_plugin:
		android_plugin.clearJwt()
	else:
		printerr("Plugin not initialized!")
