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
			menu.message_box("Scan analysis successful")
		
		
func _on_image_request_completed(image_data: Dictionary) -> void:
	if visible:
		if not image_data.has("0"):
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Failed to load image")
			return
		
		var image: Image = Image.new()
		var buffer: Array = image_data["0"]
		var error: Error = image.load_png_from_buffer(buffer)
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
		
	
func _on_farm_profile_container_on_plant_scan_button_pressed(farm_name: String) -> void:
	reset_fields()
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = true
		_show_modal_with_animation(container)
	visible = true
	%FarmName.text = farm_name
	
	
#func _process(_delta: float) -> void:
	#if OS.get_name() == "Android":
		#var keyboard_height: int = DisplayServer.virtual_keyboard_get_height()
#
		#if keyboard_height > 0 and not keyboard_is_open:
			#keyboard_is_open = true
			#%ContentContainer.size.y = original_content_container_y + keyboard_height
		#elif keyboard_height == 0 and keyboard_is_open:
			#keyboard_is_open = false
			#%ContentContainer.size.y = original_content_container_y
	
	
func _on_back_button_pressed() -> void:
	reset_fields()
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		_hide_modal_with_animation(modal_container)
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
	visible = false
	
	
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"PlantScanFields"):
		field.text = ""
	%PlantImage.texture = null
	
	
func _on_open_gallery_button_pressed() -> void:
	if %PlantImage.texture == null:
		if OS.get_name() == "Android":
			Camera.get_gallery_image()
		
		elif OS.get_name() == "Linux":
			%FileDialog.visible = true
	else:
		%PlantImage.texture = null
		%ImageLabel.visible = true
		%ImageIcon.visible = true
	
	
func _on_open_camera_button_pressed() -> void:
	Camera.get_camera_image()


func _on_submit_button_pressed() -> void:
	if %CropType.text.strip_edges() == "":
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Please enter a crop type")
		return

	if %PlantImage.texture == null:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Please upload an image")
		return
	
	var string_image_byte_data: String = str(get_scaled_png_bytes(data_image))
	var plant_scan_data: Dictionary[String, Variant] = {
		"imageBytes": string_image_byte_data,
		"cropType": %CropType.text.strip_edges(),
		"farmName": %FarmName.text.strip_edges(),
		"note": %Note.text.strip_edges()
	}
	
	if OS.get_name() == "Android":
		if NetworkState.hasNetwork():
			Scan.save_plant_scan(plant_scan_data)
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Plant scan was submitted successfully")
			
		else:
			plant_scan_data["pending"] = true
			RealmDB.save_data(JSON.stringify(plant_scan_data), "PlantHealthScan")
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Data saved locally - No internet")
		hide_modal_container()
	elif OS.get_name() == "Linux":
		Scan.save_plant_scan(plant_scan_data)
		hide_modal_container()
		
		
func get_scaled_png_bytes(image: Image, max_size: float = 512) -> PackedByteArray:
	var w: float = image.get_width()
	var h: float = image.get_height()

	if w > max_size or h > max_size:
		var maxim: float = max(w, h)
		var scale_down: float = float(max_size) / float(maxim)
		@warning_ignore("narrowing_conversion")
		image.resize(w * scale_down, h * scale_down, Image.INTERPOLATE_LANCZOS)
		
	return image.save_png_to_buffer()


func _on_crop_type_text_changed(_new_text: String) -> void:
	var is_crop_type_filled: bool = %CropType.text.strip_edges() != ""
	var has_image: bool = %PlantImage.texture != null
	%SubmitButton.disabled = not (is_crop_type_filled and has_image)
	
	
func _on_file_dialog_file_selected(path: String) -> void:
	var image: Image = Image.new()
	var error: Error = image.load(path)
	if error != OK:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Failed to load image")
		return
	var picture: Texture2D = ImageTexture.create_from_image(image)
	%PlantImage.texture = picture
	%ImageLabel.visible = false
	%ImageIcon.visible = false
	data_image = image


func hide_modal_container() -> void:
	%ImageLabel.visible = true
	%ImageIcon.visible = true
	%PlantImage.texture = null
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = false
	visible = false


func _on_smooth_scroll_container_scroll_started() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		DisplayServer.virtual_keyboard_hide()
