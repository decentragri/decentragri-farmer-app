extends VBoxContainer

var original_content_container_y: float
var keyboard_is_open: bool = false

func _ready() -> void:
	original_content_container_y = size.y
	connect_signals()



func connect_signals() -> void:
	var _1: int = Camera.image_request_completed.connect(_on_image_request_completed)
	var _2: int = Camera.image_request_failed.connect(_on_image_request_failed)


func _on_image_request_completed(image_data: Dictionary) -> void:
	if visible:
		if not image_data.has("0"):
			return
		

		var image: Image = Image.new()
		var buffer: Array = image_data["0"]
		var error: Error = image.load_png_buffer(buffer)
		if error != OK:
			return
		var picture: Texture2D = ImageTexture.create_from_image(image)
		%PlantImage.texture = picture
		%ImageLabel.visible = false
		%ImageIcon.visible = false
	
	
func _on_image_request_failed(error: String) -> void:
	print("Image request failed: " + error)
	
	
	
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
