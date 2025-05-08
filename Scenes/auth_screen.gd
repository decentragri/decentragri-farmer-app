extends Control



func _ready() -> void:
	%RegisterButton.disabled = true
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Auth.registration_complete.connect(_on_registration_complete)
	var _2: int = Auth.login_complete.connect(_on_login_complete)
	
	
func _on_registration_complete(message: Dictionary) -> void:
	if message.is_empty():
		%RegisterButton.disabled = false
	elif message.has("error"):
		%ErrorLabel.text = message.error
		%AnimationPlayer.play("error_animation")
	elif "walletAddress" in message:
		%RegisterButton.disabled = true
		%ErrorLabel.text = "Registration successful!"
		%AnimationPlayer.play("error_animation")
		await %AnimationPlayer.animation_finished
		
		var scene: PackedScene = ResourceLoader.load("res://Scenes/main_menu.tscn")
		var _1: int = get_tree().change_scene_to_packed(scene)
	
	
func _on_login_complete(_message: Dictionary) -> void:
	pass


func _on_username_login_text_changed(_new_text: String) -> void:
	# Optional: enable login button only when both fields are filled
	_update_login_button_state()

func _on_password_text_changed(_new_text: String) -> void:
	_update_login_button_state()

func _on_password_text_submitted(_new_text: String) -> void:
	# Pressing Enter in the password field submits login
	_on_login_button_pressed()

func _on_login_button_pressed() -> void:
	var username: String = %UsernameLogin.text.strip_edges()
	var password: String = %Password.text

	if username.is_empty() or password.is_empty():
		%ErrorLabel.text = "Please enter both username and password."
		%AnimationPlayer.play("error_animation")
		return

	# Trigger login
	Auth.login(username, password)
	%LoginButton.disabled = true  # Optional: disable button while logging in

func _update_login_button_state() -> void:
	# Enable login button only if both fields are filled
	%LoginButton.disabled = %UsernameLogin.text.strip_edges() == "" or %Password.text == ""


func _on_username_register_text_changed(_new_text: String) -> void:
	_update_register_button_state()

func _on_password_register_text_changed(_new_text: String) -> void:
	_update_register_button_state()

func _on_confirm_password_register_text_changed(_new_text: String) -> void:
	_update_register_button_state()

func _on_register_button_pressed() -> void:
	var username: String = %UsernameRegister.text.strip_edges()
	var password: String = %PasswordRegister.text
	var confirm_password: String = %ConfirmPasswordRegister.text

	# Username validation
	if username.length() < 6:
		_show_register_error("Username must be at least 6 characters.")
		return
	if username.find(" ") != -1:
		_show_register_error("Username cannot contain spaces.")
		return
	if not username.is_valid_identifier():
		_show_register_error("Username must be alphanumeric and use underscores only.")
		return

	# Password confirmation check
	if password != confirm_password:
		_show_register_error("Passwords do not match.")
		return
	if password.length() < 6:
		_show_register_error("Password must be at least 6 characters.")
		return

	# Perform registration

	Auth.register(username, password)
	%RegisterButton.disabled = true

func _update_register_button_state() -> void:
	var username: String = %UsernameRegister.text.strip_edges()
	var password: String= %PasswordRegister.text
	var confirm: String = %ConfirmPasswordRegister.text

	var ready_register: bool = username.length() >= 6 and password.length() >= 6 and confirm.length() >= 6
	print(ready_register)
	%RegisterButton.disabled = not ready_register

func _show_register_error(message: String) -> void:
	%ErrorLabel.text = message
	%AnimationPlayer.play("error_animation")


func _on_switch_to_register_button_pressed() -> void:
	%LoginContainer.visible = false
	%RegisterContainer.visible = true


func _on_switch_to_login_button_pressed() -> void:
	%LoginContainer.visible = true
	%RegisterContainer.visible = false
