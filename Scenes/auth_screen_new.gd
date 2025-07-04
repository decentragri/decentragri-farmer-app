extends Control



func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _2: int = Auth.login_complete.connect(_on_login_complete)
	
	
func _on_login_complete(message: Dictionary) -> void:
	if message.has("error"):
		%ErrorLabel.text = message.error
		%AnimationPlayer.play("error_animation")
		%LoginButton.disabled = true
		return
	var scene: PackedScene = ResourceLoader.load("res://Scenes/main_menu_new.tscn")
	var _1: int = get_tree().change_scene_to_packed(scene)
	loading_start(false)
	
	
func _on_username_login_text_changed(_new_text: String) -> void:
	_update_login_button_state()
	
	
func _on_password_login_text_changed(_new_text: String) -> void:
	_update_login_button_state()
	
	
func _update_login_button_state() -> void:
	# Enable login button only if both fields are filled
	%LoginButton.disabled = %UsernameLogin.text.strip_edges() == "" or %PasswordLogin.text == ""
	
	
func _on_login_button_pressed() -> void:
	var username: String = %UsernameLogin.text.strip_edges()
	var password: String = %PasswordLogin.text

	if username.is_empty() or password.is_empty():
		%ErrorLabel.text = "Please enter both username and password."
		%AnimationPlayer.play(&"error_message")
		return

	# Trigger login
	Auth.login(username, password)
	%LoginButton.disabled = true  # Optional: disable button while logging in
	loading_start(true)
	
	
func loading_start(is_loading: bool = false) -> void:
	%LoadingPanel.visible = is_loading
	if is_loading:
		await get_tree().create_timer(10.0).timeout
		%LoadingPanel.visible = false
