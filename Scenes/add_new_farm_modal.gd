extends VBoxContainer



var data_image: Image

@onready var no_image_yet_nodes: Array[Node] = [%Label2, %TextureRect2]


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _2: int = GpsLocator.gps_coordinates_received.connect(_on_gps_coordinates_received)
	var _3: int = Camera.image_request_completed.connect(_display_captured_image)
	var _4: int = Camera.image_request_failed.connect(_image_request_failed)
	var _5: int = Farm.create_farm_complete.connect(_on_create_farm_complete)
	
	
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
	
	
func _image_request_failed(message: String) -> void:
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu.message_box(message)
	
	
func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()
		
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"FarmModalFields"):
		field.text = ""
	%FarmImage.texture = null
	
	
func _on_farms_container_on_add_farm_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = true
	visible = true
	for node: Node in no_image_yet_nodes:
		node.visible = true
	
	
func _on_upload_farm_image_button_pressed() -> void:
	if %FarmImage.texture != null:
		%FarmImage.texture = null
	else:
		if OS.get_name() == "Android":
			Camera.get_gallery_image()
		elif OS.get_name() == "Linux":
			%FileDialog.visible = true
	for node: Node in no_image_yet_nodes:
		node.visible = true
	
	
func _on_caputre_image_button_pressed() -> void:
	Camera.get_camera_image()
	
	
func _on_create_farm_complete(message: Dictionary) -> void:
	if message.has("success"):
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Farm created successfully")
	
	elif message.has("error"):
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Error encountered please try again")


func _on_file_dialog_file_selected(path: String) -> void:
	var image: Image = Image.new()
	var error: Error = image.load(path)
	if error != OK:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Failed to load image")
		return
	var picture: Texture2D = ImageTexture.create_from_image(image)
	%FarmImage.texture = picture
	for node: Node in no_image_yet_nodes:
		node.visible = false
	data_image = image


func _on_submit_button_pressed() -> void:
	var crop_type: String = %CropType.text.strip_edges()
	var farm_name: String = %FarmName.text.strip_edges()
	var note: String = %Description.text.strip_edges()
	var lat_text: String = %Lat.text.strip_edges()
	var long_text: String = %Long.text.strip_edges()

	# Validate required fields
	if crop_type.is_empty():
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Crop type is required")
		return
	if farm_name.is_empty():
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Farm name is required")
		return

	var lat: float = lat_text.to_float()
	var long: float = long_text.to_float()

	# Default coordinates if not set or invalid
	if lat == 0.0 or long == 0.0:
		lat = 13.7221228
		long = 123.5792278
		
	var string_image_byte_data: String = str(Utils.get_scaled_png_bytes(data_image))
	var farm_data: Dictionary[String, Variant] = {
		"cropType": crop_type,
		"farmName": farm_name,
		"note": note,
		"imageBytes": string_image_byte_data,
		"coordinates": {
			"lat": lat,
			"lng": long
		}
	}
	Farm.create_farm(farm_data)
	# You can now pass `farm_data` to your backend or further processing
	visible = false
