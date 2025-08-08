extends VBoxContainer

signal on_plant_scan_button_pressed(farm_name: String)
signal on_soil_analysis_button_pressed(farm_id: String, farm_name: String, crop_type: String)
signal farm_scan_card_button_pressed(scan_data: Dictionary)

var farm_name: String 

func _on_farms_container_on_farm_card_button_pressed(farm_id: String) -> void:
	%FarmHeaderContainer.visible = false
	%LoaderContainer.visible = true
	%TextureProgressBar.play()
	
	%AboutContainer.visible = false
	%LoaderContainer2.visible = true
	%TextureProgressBar2.play()
	
	%StatisticsContainer.visible = false
	%LoaderContainer3.visible = true
	%TextureProgressBar3.play()
	
	%ActionsContainer.visible = false
	%LoaderContainer4.visible = true
	%TextureProgressBar4.play()
	
	Farm.get_farm_data(farm_id)
	
	
func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Farm.get_farm_data_complete.connect(_on_get_farm_data_complete)
	var _2: int = Farm.sell_farm_complete.connect(_on_sell_farm_complete)
	
	
func _on_get_farm_data_complete(farm_data: Dictionary) -> void:
	print(farm_data)
	
	%FarmName.text = farm_data.farmName
	%CropType.text = farm_data.cropType
	%CreatedAt.text = "Joined at " + farm_data.formattedCreatedAt
	%Owner.text = farm_data.owner
	%Description.text = farm_data.get("description", "No description available for this farm")
	%FarmID.text = farm_data.id
	%UpdatedAt.text = farm_data.formattedUpdatedAt
	
	%LoaderContainer.visible = false
	%FarmHeaderContainer.visible = true
	%TextureProgressBar.stop()
	
	%LoaderContainer2.visible = false
	%AboutContainer.visible = true
	%TextureProgressBar2.stop()
	
	%LoaderContainer3.visible = false
	%StatisticsContainer.visible = true
	%TextureProgressBar3.stop()
	
	%LoaderContainer4.visible = false
	%ActionsContainer.visible = true
	%TextureProgressBar4.play()
	%ScansCard.set_farm_name(farm_data.farmName)
	var image_bytes: PackedByteArray = farm_data.imageBytes
	set_image(image_bytes)
	
	
func _on_sell_farm_complete(message: Dictionary) -> void:
	if message.has("error"):
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box(str(message.error )+ " Please try again")
	else:
		for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			menu.message_box("Farm sale application submitted successfully")
	
	
func _on_plant_scan_button_pressed() -> void:
	on_plant_scan_button_pressed.emit(%FarmName.text)
	
	
func _on_soil_analysis_button_pressed() -> void:
	on_soil_analysis_button_pressed.emit(%FarmID.text, %FarmName.text, %CropType.text)
	
	
func _on_delete_farm_button_pressed() -> void:
	pass # Replace with function body.


func _on_scans_card_farm_scan_card_button_pressed(scan_data: Dictionary) -> void:
	farm_scan_card_button_pressed.emit(scan_data)
	
	
func _on_sell_farm_button_pressed() -> void:
	Farm.sell_farm(str(%FarmID.text))
	
	
func set_image(image_byte: PackedByteArray) -> void:
	if image_byte.size() == 0:
		%FarmPic.texture = preload("res://Assets/Background/auth_bg.png")
		return
		
	var image: Image = Image.new()
	var error: Error = image.load_png_from_buffer(image_byte)
	if error != OK:
		return
	var plant_scan_image: Texture2D = ImageTexture.create_from_image(image)
	%FarmPic.texture = plant_scan_image
