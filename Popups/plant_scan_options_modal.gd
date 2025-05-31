extends Control

signal plant_scan_button_pressed(button_name: String)
signal on_error_encountered(text: String)


var data_image: Image


#region 🔁 Lifecycle & Signal Connection

func _ready() -> void:
	%SubmitButton.disabled = true
	connect_signals()
	
	
func connect_signals() -> void:
	%CropTypeLine.text_changed.connect(_on_input_fields_changed)
	var _1: int = Scan.save_plant_scan_complete.connect(_on_save_plant_scan_complete)
	var _2: int = GpsLocator.gps_coordinates_received.connect(_on_gps_coordinates_received)
	var _3: int = Camera.image_request_completed.connect(_display_captured_image)
	var _4: int = Camera.image_request_failed.connect(_image_request_failed)

#endregion

#region 📍 GPS Handling

func get_gps_coordinates() -> void:
	GpsLocator.start_gps()

func _on_gps_coordinates_received(gps_string: String) -> void:
	print("📍 Raw GPS: ", gps_string)
	if gps_string == null or gps_string.strip_edges() == "":
		on_error_encountered.emit("GPS data is invalid or unavailable.")
		return

	var json_result: Dictionary = JSON.parse_string(gps_string)
	if json_result == null or json_result.has("error"):
		on_error_encountered.emit("GPS data is invalid or unavailable.")

	var gps_data: Dictionary = json_result
	if gps_data.has("lat") and gps_data.has("lng"):
		%LatitudeLine.text = str(gps_data["lat"])
		%LongtitudeLine.text = str(gps_data["lng"])
	else:
		on_error_encountered.emit("Missing latitude or longitude in GPS data.")

#endregion

#region 📸 Image Capture and Display

func _on_image_capture_button_pressed() -> void:
	plant_scan_button_pressed.emit("ImageCaptureButton")
	
	
func _on_choose_image_button_pressed() -> void:
	plant_scan_button_pressed.emit("ChooseImageButton")
	
	
func _display_captured_image(image_data: Dictionary) -> void:
	if not image_data.has("0"):
		on_error_encountered.emit("No image data received")
		return
	

	var image: Image = Image.new()
	var buffer: Array = image_data["0"]
	var error: Error = image.load_png_from_buffer(buffer)
	if error != OK:
		on_error_encountered.emit("Failed to load image from buffer")
		print("Image error code: ", error)
		return

	var uploaded_pic: Texture2D = ImageTexture.create_from_image(image)
	%UploadedPic.texture = uploaded_pic
	_on_input_fields_changed()
	%OptionsContainer.visible = false
	%FormContainer.visible = true
	get_gps_coordinates()
	data_image = image

#endregion

#region 📝 Input Validation

func _on_input_fields_changed() -> void:
	var is_crop_type_filled: bool = %CropTypeLine.text.strip_edges() != ""
	var has_image: bool = %UploadedPic.texture != null
	%SubmitButton.disabled = not (is_crop_type_filled and has_image)
	
	
func _on_notes_line_text_changed(_new_text: String) -> void:
	_on_input_fields_changed()
	
func _on_crop_type_line_text_changed(_new_text: String) -> void:
	_on_input_fields_changed()
#endregion

#region ✅ Submit Handling

func _on_submit_button_pressed() -> void:
	if %CropTypeLine.text.strip_edges() == "":
		on_error_encountered.emit("Crop type is required.")
		return

	if %UploadedPic.texture == null:
		on_error_encountered.emit("Please upload a plant image.")
		return
	
	var string_image_byte_data: String  = str(get_scaled_png_bytes(data_image))
	var _plant_scan_data: Dictionary[String, Variant] = {
		"imageBytes": string_image_byte_data,
		"cropType": %CropTypeLine.text.strip_edges(),
		"location": {
			"lat": %LatitudeLine.text.to_float(),
			"lng": %LongtitudeLine.text.to_float(),
		},
		"note": %NotesLine.text.strip_edges()
	}

	Scan.save_plant_scan(_plant_scan_data)
	#var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	#root_node.loading_start(true)

func _on_save_plant_scan_complete(message: Dictionary) -> void:
	if message.has("error"):
		on_error_encountered.emit(message.error + " Please try again")
	elif message.has("success"):
		on_error_encountered.emit(message.success)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false, "not bio")
	visible = false

#endregion

#region 🔙 UI Navigation & State

func _on_back_button_pressed() -> void:
	visible = false
	%OptionsContainer.visible = true
	%FormContainer.visible = false

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false
		%OptionsContainer.visible = true
		%FormContainer.visible = false
	
	
func _on_panel_visibility_changed() -> void:
	if visible:
		get_gps_coordinates()
	
	


#endregion

#region ⚠️ Error Handling

func _image_request_failed(message: String) -> void:
	on_error_encountered.emit(message)

#endregion


func get_scaled_png_bytes(image: Image, max_size: float = 512) -> PackedByteArray:
	var w: float = image.get_width()
	var h: float = image.get_height()

	if w > max_size or h > max_size:
		var maxim: float = max(w, h)
		var scale_down: float = float(max_size) / float(maxim)
		@warning_ignore("narrowing_conversion")
		image.resize(w * scale_down, h * scale_down, Image.INTERPOLATE_LANCZOS)
		
	
	return image.save_png_to_buffer()
