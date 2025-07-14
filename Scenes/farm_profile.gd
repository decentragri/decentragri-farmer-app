extends VBoxContainer

signal on_plant_scan_button_pressed(farm_name: String)
signal on_soil_analysis_button_pressed(farm_id: String)


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
	
	Farmer.get_farm_data(farm_id)
	
	
func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Farmer.get_farm_data_complete.connect(_on_get_farm_data_complete)

	
	
func _on_get_farm_data_complete(farm_data: Dictionary) -> void:
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
	
	
func _on_plant_scan_button_pressed() -> void:
	on_plant_scan_button_pressed.emit(%FarmName.text)
	
	
func _on_soil_analysis_button_pressed() -> void:
	on_soil_analysis_button_pressed.emit(%FarmID.text)
	
	
func _on_delete_farm_button_pressed() -> void:
	pass # Replace with function body.
