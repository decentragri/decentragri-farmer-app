extends VBoxContainer

var original_content_container_y: float
var keyboard_is_open: bool = false

var data_image: Image


func _ready() -> void:
	original_content_container_y = size.y
	connect_signals()



func connect_signals() -> void:
	var _1: int = Camera.image_request_completed.connect(_on_image_request_completed)
	var _2: int = Camera.image_request_failed.connect(_on_image_request_failed)
	var _3: int = Scan.save_plant_scan_complete.connect(_on_save_plant_scan_complete)


func _on_save_plant_scan_complete(message: Dictionary) -> void:
	if message.has("error"):
		match message.error:
			"Data saved locally - No internet":
				for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
					menu.message_box("Data saved locally - No internet")
				return
			_:
				for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
					menu.message_box(message.error)
				return
	else:
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Scan was submitted successfully")
		
	
	
func _on_image_request_completed(image_data: Dictionary) -> void:
	if visible:
		if not image_data.has("0"):
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Failed to load image")
			return
		
		var image: Image = Image.new()
		var buffer: Array = image_data["0"]
		var error: Error = image.load_png_buffer(buffer)
		if error != OK:
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Failed to load image")
			return
		var picture: Texture2D = ImageTexture.create_from_image(image)
		%PlantImage.texture = picture
		%ImageLabel.visible = false
		%ImageIcon.visible = false
		data_image = image
	
	
func _on_image_request_failed(error: String) -> void:
	for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		main.message_box(error)
		
	
func _on_farm_profile_container_on_plant_scan_button_pressed(_farm_id: String) -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = true
	visible = true
	reset_fields()
	
	
func _process(_delta: float) -> void:
	if OS.get_name() == "Android":
		var keyboard_height: int = DisplayServer.virtual_keyboard_get_height()

		if keyboard_height > 0 and not keyboard_is_open:
			keyboard_is_open = true
			%ContentContainer.size.y = original_content_container_y + keyboard_height
		elif keyboard_height == 0 and keyboard_is_open:
			keyboard_is_open = false
			%ContentContainer.size.y = original_content_container_y
	
	
func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()
	
	
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"PlantScanFields"):
		field.text = ""
	%PlantImage.texture = null
	
	
func _on_open_gallery_button_pressed() -> void:
	if %PlantImage.texture == null:
		Camera.get_gallery_image()
	else:
		%PlantImage.texture = null
		%ImageLabel.visible = true
		%ImageIcon.visible = true
	
	
func _on_open_camera_button_pressed() -> void:
	Camera.get_camera_image()


func _on_submit_button_pressed() -> void:
	if %CropTypeLine.text.strip_edges() == "":
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Please enter a crop type")
		return

	if %UploadedPic.texture == null:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Please upload an image")
		return
	
	var string_image_byte_data: String  = str(get_scaled_png_bytes(data_image))
	var plant_scan_data: Dictionary[String, Variant] = {
		"imageBytes": string_image_byte_data,
		"cropType": %CropTypeLine.text.strip_edges(),
		"farmName": %FarmName.text.strip_edges(),
		"note": %NotesLine.text.strip_edges()
	}
	
	if NetworkState.hasNetwork():
		Scan.save_plant_scan(plant_scan_data)
	else:
		plant_scan_data["pending"] = true
		RealmDB.save_data(JSON.stringify(plant_scan_data), "PlantHealthScan")
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Data saved locally - No internet")
	visible = false
	




func get_scaled_png_bytes(image: Image, max_size: float = 512) -> PackedByteArray:
	var w: float = image.get_width()
	var h: float = image.get_height()

	if w > max_size or h > max_size:
		var maxim: float = max(w, h)
		var scale_down: float = float(max_size) / float(maxim)
		@warning_ignore("narrowing_conversion")
		image.resize(w * scale_down, h * scale_down, Image.INTERPOLATE_LANCZOS)
		
	return image.save_png_to_buffer()
