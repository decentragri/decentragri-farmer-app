extends Control



func _ready() -> void:
	set_display()
	connect_signals()
	$HBoxContainer/MainContainer.button_pressed = true
	
	
func connect_signals() -> void:
	pass
	
	
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
	
	
func _on_scan_button_pressed() -> void:
	%SoilMeterValuesModal.visible = true
	#SensorCamera.start_scanner()
	
	
func _on_soil_meter_values_modal_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")
	
	
func _on_scan_history_button_pressed() -> void:
	show_window("ScanHistoryContainer")
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "ScanHistoryContainer")
	
	
func _on_scan_history_container_scan_entry_details_button_pressed(details: Dictionary) -> void:
	%ScanEntryDetails.details_display(details)
	
	
func _on_main_container_pressed() -> void:
	# Ensure only "MainContainer" is marked as pressed
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "MainContainer")
	show_window("MainContainer")
	
	
func show_window(window_name: String) -> void:
	for  windows: VBoxContainer in %WindowsContainer.get_children():
		if windows.name != window_name:
			windows.visible = false
		else:
			windows.visible = true
	
	
func _on_staking_container_on_error_encountered(text: String) -> void:
	%ErrorLabel.text = text
	%AnimationPlayer.play("error_animation")


func _on_staking_button_pressed() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group("WindowButtons"):
		button.button_pressed = (button.name == "StakingContainer")
	show_window("StakingContainer")
