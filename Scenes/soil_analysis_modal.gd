extends VBoxContainer

var original_content_container_y: float
var keyboard_is_open: bool = false



func _ready() -> void:
	original_content_container_y = %ContentContainer.size.y
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Scan.save_soil_meter_scan_complete.connect(_on_save_soil_meter_scan_complete)
	
	
func _on_save_soil_meter_scan_complete(message: Dictionary) -> void:
	if message.has("error"):
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box(str(message.error )+ " Please try again")
		
	else:
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Scan was submitted successfully")
		reset_fields()

func _on_farm_profile_container_on_soil_analysis_button_pressed(_farm_id: String, farm_name: String, crop_type: String) -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = true
		_show_modal_with_animation(container)
	visible = true
	%FarmName.text = farm_name
	%CropType.text = crop_type
	
	
func _process(_delta: float) -> void:
	if OS.get_name() == "Android":
		var keyboard_height: int = DisplayServer.virtual_keyboard_get_height()
		if keyboard_height > 0:
			keyboard_is_open = true
			%ContentContainer.size.y = original_content_container_y + keyboard_height
		elif keyboard_height == 0 and keyboard_is_open:
			keyboard_is_open = false
			%ContentContainer.size.y = original_content_container_y
	
	
func _on_back_button_pressed() -> void:
	reset_fields()
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		_hide_modal_with_animation(modal_container)
	visible = false
	
	
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"SoilAnalysisFields"):
		field.text = ""
	
	
func _on_crop_type_text_changed(new_text: String) -> void:
	var trimmed_text: String = new_text.strip_edges()
	if trimmed_text == "":
		%CropTypeLine.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Crop type cannot be empty.")
		return

	# Optional: Check for only letters/spaces (no numbers/symbols)
	if not trimmed_text.is_valid_identifier() and not trimmed_text.is_valid_float(): # crude check
		var pattern: RegEx = RegEx.new()
		var _1: Error = pattern.compile("^[A-Za-z ]+$")
		if not pattern.search(trimmed_text):
			%CropTypeLine.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Crop type must only contain letters and spaces.")
			return
	
	
func _on_moisture_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100.0:
			%Moisture.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Moisture value must be between 0% and 100%.")
	else:
		%Moisture.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid moisture input. Please enter a number.")
	
	
func _on_ph_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 14.0:
			%PH.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("pH value out of range (0–14).")
	else:
		%PH.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid pH input. Please enter a number.")
	
	
func _on_temperature_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < -20.0 or value > 60.0:
			%Temperature.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Temperature value out of range (-20°C to 60°C).")
	else:
		%Temperature.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid temperature input. Please enter a number.")


func _on_fertility_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float = new_text.to_float()
		if value < 0.0 or value > 2000.0:
			%Fertility.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Fertility value out of range (0-2000 µS/cm).")
	else:
		%Fertility.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid fertility input. Please enter a number.")


func _on_sunlight_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100000.0:
			%Sunlight.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Sunlight value out of range (0–100000 lux).")
	else:
		%Sunlight.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid sunlight input. Please enter a number.")


func _on_humidity_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100.0:
			%Humidity.text = ""
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Humidity value out of range (0–100).")
	else:
		%Humidity.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Invalid humidity input. Please enter a number.")
	
	
func _is_valid_float(text: String) -> bool:
	return text.is_valid_float()
	
	
func _on_submit_button_pressed() -> void:
	var fields: Dictionary[String, Variant] = {
		"moisture": %Moisture,
		"ph": %PH,
		"temperature": %Temperature,
		"fertility": %Fertility,
		"sunlight": %Sunlight,
		"humidity": %Humidity,
	}

	var data: Dictionary[String, Variant] = {}

	for key: String in fields.keys():
		var text: String = fields[key].text.strip_edges()
		if text == "":
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("%s field is empty." % key.capitalize())
			return
		if not _is_valid_float(text):
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("%s value is not a valid number." % key.capitalize())
			return
		data[key] = text.to_float()

	if %CropType != null and %CropType.text.strip_edges() != "":
		data["cropType"] = %CropType.text.strip_edges()
		data["farmName"] = %FarmName.text.strip_edges()
	else:
		data["cropType"] = null
	

	data["sensorId"] = "sensor_def"
	data["createdAt"] = Time.get_datetime_string_from_system()
	data["id"] = Utils.generate_uuid_v4()

	var sensor_data: Dictionary = {
		"sensorData": data
	}
	if OS.get_name() == "Android":
		if NetworkState.hasNetwork():
			Scan.save_soil_meter_scan(sensor_data)
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Scan was submitted successfully")
		else:
			sensor_data["pending"] = true	
			RealmDB.save_data(JSON.stringify(sensor_data), "SoilAnalysisScan")
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Data saved locally - No internet")
				
	elif OS.get_name() == "Linux":
		Scan.save_soil_meter_scan(sensor_data)
		hide_modal_container()
	
	
func hide_modal_container() -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = false
	visible = false
	
	
func _show_modal_with_animation(container: VBoxContainer) -> void:
	container.visible = true
	container.modulate.a = 0.0
	var tween: Tween = create_tween()
	var _1: Tween = tween.set_trans(Tween.TRANS_SINE)
	var _2: Tween = tween.set_ease(Tween.EASE_OUT)
	var _3: PropertyTweener = tween.tween_property(container, "modulate:a", 1.0, 0.25)
	
	
func _hide_modal_with_animation(container: VBoxContainer) -> void:
	var tween: Tween = create_tween()
	var _1: Tween = tween.set_trans(Tween.TRANS_SINE)
	var _2: Tween = tween.set_ease(Tween.EASE_IN)
	var _3: PropertyTweener = tween.tween_property(container, "modulate:a", 0.0, 0.2)
	var _4: CallbackTweener = tween.tween_callback(Callable(container, "hide"))
