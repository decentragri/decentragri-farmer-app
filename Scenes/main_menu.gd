extends Control

#region 🔁 Ready & Signal Setup

func _ready() -> void:
	set_display()
	connect_signals()
	$HBoxContainer/MainContainer.button_pressed = true
	Weather.get_current_weather("Manila")
	loading_start(true, "bio")
	
	# Start sync of pending data if network is available and on Android
	if OS.get_name() == "Android":
		_check_and_sync_pending_data()

func _check_and_sync_pending_data() -> void:
	# Wait a bit to ensure all systems are initialized
	await get_tree().create_timer(1.0).timeout
	
	if NetworkState.hasNetwork():
		print("App started with network connection, checking for pending data to sync...")
		NetworkState._sync_pending_data()

func connect_signals() -> void:
	var _1: int = Weather.get_current_weather_complete.connect(_on_get_current_weather_complete)
	var _2: int = Weather.get_weather_icon_complete.connect(_on_get_weather_icon_complete)
	var _3: int = BiometricAuth.bio_auth_success.connect(_on_bio_auth_success)
	var _4: int = BiometricAuth.bio_auth_failed.connect(_on_bio_failed)
	var _5: int  = %ScanButton.pressed.connect(on_scan_button_pressed)
	
	# Connect sync status signals
	if OS.get_name() == "Android":
		var _6: int = NetworkState.sync_completed.connect(_on_sync_completed)
		var _7: int = NetworkState.sync_progress.connect(_on_sync_progress)


#endregion

#region 🪟 Window Switching & Loading State

func show_window(window_name: String) -> void:
	for windows: VBoxContainer in %WindowsContainer.get_children():
		windows.visible = (windows.name == window_name)

func loading_start(is_loading: bool = false, is_bio_verification: String = "not") -> void:
	%LoadingPanel.visible = is_loading
	if is_bio_verification == "bio":
		%LoadingLabel.text = "Please verify"
		%VerifyBioButton.visible = true
	else:
		%LoadingLabel.text = "Please wait"
		%VerifyBioButton.visible = false

#endregion

#region 🌱 Greeting Logic

func set_display() -> void:
	set_greetings_label()

func set_greetings_label() -> void:
	var greetings: Array[String] = [
		"Hope your crops are thriving!",
		"Let's grow something amazing today!",
		"Sunshine and success to you!",
		"Plant good seeds, reap great harvests!",
		"The soil is calling — time to shine!",
		"Let the earth reward your hard work!",
		"A perfect day for smart farming!",
		"Nature’s ready — are you?",
		"May your yields be plentiful!",
		"Let’s turn dirt into gold!"
	]
	var random_greeting: String = greetings[randi() % greetings.size()]
	%GreetingsLabel.text = "Hello " + User.username + "!\n" + random_greeting

#endregion

#region 🔐 Biometric Authentication

func _on_bio_auth_success() -> void:
	if visible: 
		loading_start(false)
		%VerifyBioButton.visible = false
		%ErrorLabel.text = "Successful"
		%AnimationPlayer.play(&"error_animation")

func _on_bio_failed(error: String) -> void:
	if visible: 
		%ErrorLabel.text =  error +  " Please try again"
		%AnimationPlayer.play(&"error_animation")
		loading_start(true, "bio")

func _on_verify_bio_button_pressed() -> void:
	BiometricAuth.start_biometrics_auth()

#endregion

#region ☁️ Weather Display

func _on_get_current_weather_complete(current_weather: Dictionary) -> void:
	if current_weather.has("error"):
		return
	var uri: String = current_weather.current.condition.icon
	Weather.get_weather_icon(uri)

func _on_get_weather_icon_complete(image: Dictionary) -> void:
	%WeatherIcon.texture = image.texture

#endregion

#region 🧪 Scan Logic

func on_scan_button_pressed() -> void:
	%ChooseScanModal.visible = true


func _on_choose_scan_modal_scan_button_pressed(button_name: String) -> void:
	print("Scan button pressed: ", button_name)
	match button_name:
		"SoilScanButton":
			%SoilMeterValuesModal.visible = true
		"PlantScanButton":
			%PlantScanOptionsModal.visible = true
			

func _on_plant_scan_options_modal_plant_scan_button_pressed(button_name: String) -> void:
	var image_functions: Dictionary[String, Callable] = {
		"ImageCaptureButton": Camera.get_camera_image,
		"ChooseImageButton": Camera.get_gallery_image
	}
	if image_functions.has(button_name):
		image_functions[button_name].call()

#endregion

#region 🪪 Profile View

func _on_profile_button_pressed() -> void:
	show_window("ProfileContainer")
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "ProfileContainer")

func _on_profile_container_wallet_token_button_pressed(token_data: Dictionary) -> void:
	%SendTokens.token_data(token_data)

#endregion

#region 💰 Staking View

func _on_staking_button_pressed() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "StakingContainer")
	show_window("StakingContainer")
	loading_start(true, "not bio")

#endregion

#region 🧾 Scan History View

func _on_scan_history_button_pressed() -> void:
	%ScanOptionsModal.visible = true

func _on_scan_options_modal_scan_history_button_pressed(button_name: String) -> void:
	%ScanHistoryContainer.set_history_mode(button_name)
	show_window("ScanHistoryContainer")

func _on_scan_history_container_scan_entry_details_button_pressed(details: Dictionary) -> void:
	%ScanEntryDetails.details_display(details)

#endregion

#region 🏠 Main View Button

func _on_main_container_pressed() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "MainContainer")
	show_window("MainContainer")

#endregion

#region 🏡 My Farm View

func _on_my_farm_button_pressed() -> void:
	show_window("MyFarmContainer")
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "MyFarmButton")

func _on_my_farm_container__create_farm_button_pressed() -> void:
	%CreateFarmModal.visible = true

func _on_my_farm_container_on_button_farm_pressed(farm_id:String) -> void:
	%FarmModal.get_farm_data(farm_id)


#endregion










#region ⚠️ Error Handling


func error_or_message(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_soil_meter_values_modal_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_profile_container_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_staking_container_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_send_tokens_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_plant_scan_options_modal_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_create_farm_modal_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_farm_modal__on_error_encountered(text:String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

func _on_my_farm_container__on_error_encountered(text:String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")

#endregion

#region 📡 Sync Status Handlers

func _on_sync_completed(success: bool, message: String) -> void:
	print("Sync completed: ", success, " - ", message)
	# You can add UI updates here if needed

func _on_sync_progress(current: int, total: int, message: String) -> void:
	print("Sync progress: %d/%d - %s" % [current, total, message])
	# You can add progress UI updates here if needed

#endregion
