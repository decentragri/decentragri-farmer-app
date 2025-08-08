extends Control

signal on_error_encountered(text: String)

@onready var line_edits: Array[LineEdit] = [%FarmName, %CropType, %Description]
var farm_image: String

func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _2: int = GpsLocator.gps_coordinates_received.connect(_on_gps_coordinates_received)
	var _3: int = Camera.image_request_completed.connect(_display_captured_image)
	var _4: int = Camera.image_request_failed.connect(_image_request_failed)
	var _5: int = Farm.create_farm_complete.connect(_on_create_farm_complete)


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
	farm_image = str(buffer)


func _image_request_failed(message: String) -> void:
	on_error_encountered.emit(message)


func _on_gps_coordinates_received(gps_string: String) -> void:
	if gps_string == null or gps_string.strip_edges() == "":
		on_error_encountered.emit("GPS data is invalid or unavailable.")
		return

	var json_result: Dictionary = JSON.parse_string(gps_string)
	if json_result == null or json_result.has("error"):
		on_error_encountered.emit("GPS data is invalid or unavailable.")
		return

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


func _on_submit_button_pressed() -> void:
	var farm_name: String = %FarmName.text.strip_edges()
	var crop_type: String = %CropType.text.strip_edges()
	var description: String = %Description.text.strip_edges()
	var lat_text: String = %LatitudeLine.text.strip_edges()
	var lng_text: String = %LongtitudeLine.text.strip_edges()

	if farm_name == "":
		on_error_encountered.emit("Farm name is required.")
		return

	if crop_type == "":
		on_error_encountered.emit("Crop type is required.")
		return

	var lat: float = 0.0
	var lng: float = 0.0
	var include_placeholder: bool = true

	if lat_text != "" and lng_text != "":
		if lat_text.is_valid_float() and lng_text.is_valid_float():
			lat = lat_text.to_float()
			lng = lng_text.to_float()
			include_placeholder = false
		else:
			on_error_encountered.emit("Latitude and longitude must be valid numbers.")
			return

	# Use empty string if image is null or not set
	var image_data: String = farm_image if farm_image != "" else ""
	print(image_data)
	
	var farm_data: Dictionary[String, Variant] = {
		"farmName": farm_name,
		"cropType": crop_type,
		"description": description,
		"image": image_data,
		"location": {
			"lat": lat,
			"lng": lng
		}
	}
	
	
	print(farm_data)

	if include_placeholder:
		print("No coordinates provided. Using default placeholder location (0.0, 0.0)")

	if image_data == "":
		print("No image provided. Using empty string as placeholder.")

	on_error_encountered.emit("Farm creation submitted.")
	Farm.create_farm(farm_data)

	
func _on_create_farm_complete(message: Dictionary) -> void:
	if message.has("success"):
		on_error_encountered.emit(message.success)
		await get_tree().create_timer(3.0).timeout
		visible = false
	elif message.has("error"):
		on_error_encountered.emit(message.error)
		
