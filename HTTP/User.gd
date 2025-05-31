extends Node

signal user_data_received(user_data: Dictionary)

var username: String
var wallet_address: String


func _ready() -> void:
	var _1: int = Auth.session_check_complete.connect(_on_authentication_complete)
	var _2: int = Auth.login_complete.connect(_on_authentication_complete)
	var _3: int = Auth.registration_complete.connect(_on_authentication_complete)
	
	
func _on_authentication_complete(user_data: Dictionary) -> void:

	if user_data.is_empty() or user_data.has("error"):
		return
	wallet_address = user_data.walletAddress
	username = user_data.username
	user_data_received.emit(user_data)
