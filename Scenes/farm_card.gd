extends Panel

signal on_farm_card_button_pressed(farm_id: String)

func farm_data(farm: Dictionary) -> void:
	%FarmName.text = farm.farmName
	%FarmID.text = farm.id
	%CropType.text = farm.cropType
	%UpdatedAt.text = farm.formattedUpdatedAt
	%CreatedAt.text = farm.formattedCreatedAt
	var image_bytes: PackedByteArray = farm.imageBytes
	set_image(image_bytes)
	
	
func _on_farm_button_pressed() -> void:
	on_farm_card_button_pressed.emit(%FarmID.text)
	
	
func set_image(image_byte: PackedByteArray) -> void:
	if image_byte.size() == 0:
		%FarmImage.texture = preload("res://Assets/Background/auth_bg.png")
		return
	var image: Image = Image.new()
	var error: Error = image.load_png_from_buffer(image_byte)
	if error != OK:
		return
	var plant_scan_image: Texture2D = ImageTexture.create_from_image(image)
	%FarmImage.texture = plant_scan_image
