extends Control


signal on_error_encountered(text: String)

const uuid: Script = preload("res://HTTP/UUID.gd")


func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Scan.save_soil_meter_scan_complete.connect(_on_save_soil_meter_scan_complete)
	
	
func _on_save_soil_meter_scan_complete(message: Dictionary) -> void:
	if message.has("error"):
		on_error_encountered.emit(str(message.error )+ " Please try again")
		
	else:
		on_error_encountered.emit("Scan was submitted successfully")
		reset_line_edits()

	
func _on_croptype_line_text_changed(new_text: String) -> void:
	var trimmed_text: String = new_text.strip_edges()
	if trimmed_text == "":
		%CropTypeLine.text = ""
		on_error_encountered.emit("Crop type cannot be empty.")
		return

	# Optional: Check for only letters/spaces (no numbers/symbols)
	if not trimmed_text.is_valid_identifier() and not trimmed_text.is_valid_float(): # crude check
		var pattern: RegEx = RegEx.new()
		var _1: Error = pattern.compile("^[A-Za-z ]+$")
		if not pattern.search(trimmed_text):
			%CropTypeLine.text = ""
			on_error_encountered.emit("Crop type must only contain letters and spaces.")
			return
	
	
# Fertility (0–2000 µS/cm is a typical upper bound)
func _on_fertility_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float = new_text.to_float()
		if value < 0.0 or value > 2000.0:
			%FertilityLine.text = ""
			on_error_encountered.emit("Fertility value out of range (0-2000 µS/cm).")
	else:
		%FertilityLine.text = ""
		on_error_encountered.emit("Invalid fertility input. Please enter a number.")
		
	
# Moisture (0–100%)
func _on_moisture_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100.0:
			%MoistureLine.text = ""
			on_error_encountered.emit("Moisture value must be between 0% and 100%.")
	else:
		%MoistureLine.text = ""
		on_error_encountered.emit("Invalid moisture input. Please enter a number.")
	
	
# pH (typically 0–14, normal soil: ~5.5–8)
func _on_ph_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 14.0:
			%PHLine.text = ""
			on_error_encountered.emit("pH value out of range (0–14).")
	else:
		%PHLine.text = ""
		on_error_encountered.emit("Invalid pH input. Please enter a number.")
	
	
# Temperature (Celsius, e.g., -20 to 60 for soil sensors)
func _on_temperature_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < -20.0 or value > 60.0:
			%TemperatureLine.text = ""
			on_error_encountered.emit("Temperature value out of range (-20°C to 60°C).")
	else:
		%TemperatureLine.text = ""
		on_error_encountered.emit("Invalid temperature input. Please enter a number.")
	
	
# Sunlight (lux, 0–100,000 is valid for Earth sunlight)
func _on_sunlight_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100000.0:
			%SunlightLine.text = ""
			on_error_encountered.emit("Sunlight value out of range (0–100000 lux).")
	else:
		%SunlightLine.text = ""
		on_error_encountered.emit("Invalid sunlight input. Please enter a number.")
	
	
# Humidity (0–100%)
func _on_humidity_line_text_changed(new_text: String) -> void:
	if _is_valid_float(new_text):
		var value: float  = new_text.to_float()
		if value < 0.0 or value > 100.0:
			%HumidityLine.text = ""
			on_error_encountered.emit("Humidity value must be between 0% and 100%.")
	else:
		%HumidityLine.text = ""
		on_error_encountered.emit("Invalid humidity input. Please enter a number.")


func _on_submit_button_pressed() -> void:
	var fields: Dictionary[String, Variant] = {
		"fertility": %FertilityLine,
		"moisture": %MoistureLine,
		"ph": %PHLine,
		"temperature": %TemperatureLine,
		"sunlight": %SunlightLine,
		"humidity": %HumidityLine,
	}

	var data: Dictionary[String, Variant] = {}

	for key: String in fields.keys():
		var text: String = fields[key].text.strip_edges()
		if text == "":
			on_error_encountered.emit("%s field is empty." % key.capitalize())
			return
		if not _is_valid_float(text):
			on_error_encountered.emit("%s value is not a valid number." % key.capitalize())
			return
		data[key] = text.to_float()

	if %CropTypeLine != null and %CropTypeLine.text.strip_edges() != "":
		data["cropType"] = %CropTypeLine.text.strip_edges()
	else:
		data["cropType"] = null

	data["username"] = User.username
	data["sensorId"] = "sensor_def"
	data["createdAt"] = Time.get_datetime_string_from_system()
	data["id"] = uuid.generate_uuid_v4()

	var sensor_data: Dictionary = {
		"sensorData": data
	}

	print(sensor_data)

	if NetworkState.hasNetwork():
		Scan.save_soil_meter_scan(sensor_data)
	else:
		sensor_data["pending"] = true
		RealmDB.save_data(JSON.stringify(sensor_data))
		print("Network unavailable. Saved scan data to RealmDB for later sync.")
	visible = false
	
	
# Utility function to check if a string is a valid float
func _is_valid_float(text: String) -> bool:
	return text.is_valid_float()
	
	
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		pass
		
		
func reset_line_edits() -> void:
	for line_edit: LineEdit in get_tree().get_nodes_in_group(&"MeterValuesLine"):
		line_edit.text = ""
	
	
func _on_back_button_pressed() -> void:
	visible = false
	reset_line_edits()


func _on_visibility_changed() -> void:
	if visible:
		%CropTypeLine.text = Scan.crop_type
		%FarmName.text = Scan.farm_name
