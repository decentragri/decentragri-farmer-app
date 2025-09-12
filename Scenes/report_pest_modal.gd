extends VBoxContainer

var data_image: Image

@onready var no_image_yet_nodes: Array[Node] = [%Label2, %TextureRect2]


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _2: int = GpsLocator.gps_coordinates_received.connect(_on_gps_coordinates_received)
	var _3: int = Camera.image_request_completed.connect(_display_captured_image)
	var _4: int = Camera.image_request_failed.connect(_image_request_failed)
	var _5: int = Pest.save_pest_report_complete.connect(_on_save_pest_report_complete)


func _on_save_pest_report_complete(message: Dictionary) -> void:
	if message.has("error"):
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box(message.error)
	else:
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Pest report submitted successfully")


func _image_request_failed(message: String) -> void:
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu.message_box(message)


func _on_gps_coordinates_received(gps_string: String) -> void:
	if gps_string == null or gps_string.strip_edges() == "":
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("GPS data is invalid or unavailable")
			
	
func _display_captured_image(image_data: Dictionary) -> void:
	if visible:
		for node: Node in no_image_yet_nodes:
			node.visible = false
		if not image_data.has("0"):
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("No image data received")
			return
		var image: Image = Image.new()
		var buffer: Array = image_data["0"]
		var error: Error = image.load_png_from_buffer(buffer)
		if error != OK:
			for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				menu.message_box("Failed to load image from buffer")
			print("Image error code: ", error)
			return
		
		var uploaded_pic: Texture2D = ImageTexture.create_from_image(image)
		%FarmImage.texture = uploaded_pic
		data_image = image


func _on_file_dialog_file_selected(path: String) -> void:
	var image: Image = Image.new()
	var error: Error = image.load(path)
	if error != OK:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Failed to load image")
		return
	var picture: Texture2D = ImageTexture.create_from_image(image)
	%PestImage.texture = picture
	for node: Node in no_image_yet_nodes:
		node.visible = false
	data_image = image


func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()
	
	
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"PestModalFields"):
		field.text = ""
	%PestImage.texture = null
	
	
func _on_severity_level_text_changed(severity: String) -> void:
	var allowed_values: Array[String]= ["1", "2", "3", "4", "5"]
	if severity in allowed_values:
		print("✅ Valid severity: ", severity)
	else:
		%SeverityLevel.text = ""
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("❌ Invalid severity: ", severity, " Only values 1 to 5 is allowed")


func _on_submit_button_pressed() -> void:
	var pest_type: String = %PestType.text.strip_edges()
	var crop_affected: String = %CropAffected.text.strip_edges()
	var severity_level: int = %SeverityLevel.text.strip_edges().to_int()
	var lat_text: String = %Lat.text.strip_edges()
	var long_text: String = %Long.text.strip_edges()

	var lat: float = lat_text.to_float()
	var long: float = long_text.to_float()

	var string_image_byte_data: String = str(Utils.get_scaled_png_bytes(data_image))

	if lat == 0.0 or long == 0.0:
		lat = 13.7221228
		long = 123.5792278
		
	if pest_type.is_empty():
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Pest type is required")
			return
	if crop_affected.is_empty():
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Crop affected is required")
			return
	if severity_level == 0:
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Severity_level is required")
			return
	var pest_data: Dictionary = {
		"pestType": pest_type,
		"cropAffected": crop_affected,
		"severityLevel": severity_level,
		"coordinates": {
			"lat": lat,
			"lng": long
		},
		"dateTime": Time.get_datetime_string_from_system(),
		"imageBytes": string_image_byte_data
	}
	
	Pest.save_pest_report(pest_data)
	visible = false
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu.message_box("Pest report submitted")


func _on_upload_pest_image_button_pressed() -> void:
	if %PestImage.texture != null:
		%PestImage.texture = null
	else:
		if OS.get_name() == "Android":
			Camera.get_gallery_image()
		elif OS.get_name() == "Linux":
			%FileDialog.visible = true
	for node: Node in no_image_yet_nodes:
		node.visible = true


func _on_home_container_report_pest_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = true
	visible = true
	for node: Node in no_image_yet_nodes:
		node.visible = true
