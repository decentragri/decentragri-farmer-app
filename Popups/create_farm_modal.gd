extends Control

signal on_error_encountered(text: String)

var line_edits: Array[LineEdit] = [%FarmName, %CropType, %Description]


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _2: int = GpsLocator.gps_coordinates_received.connect(_on_gps_coordinates_received)
	var _3: int = Camera.image_request_completed.connect(_display_captured_image)
	var _4: int = Camera.image_request_failed.connect(_image_request_failed)
	
	
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
	%FarmPicture.texture = uploaded_pic


func _image_request_failed(message: String) -> void:
	on_error_encountered.emit(message)
	
	
func _on_gps_coordinates_received(gps_string: String) -> void:
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


func _on_back_button_pressed() -> void:
	visible = false
	%FarmPicture.texture = null
	for line: LineEdit in line_edits:
		line.text = ""
	
	
func _on_upload_picture_button_pressed() -> void:
	if %FarmPicture.texture != null:
		%FarmPicture.texture = null
	else:
		%ChoosePhotoModal.visible = true


func _on_image_capture_button_pressed() -> void:
	Camera.get_camera_image()


func _on_choose_image_button_pressed() -> void:
	Camera.get_gallery_image()


func _on_visibility_changed() -> void:
	get_gps_coordinates()
	
	
func get_gps_coordinates() -> void:
	GpsLocator.start_gps()
