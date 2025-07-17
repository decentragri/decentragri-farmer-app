extends Panel

signal on_farm_card_button_pressed(farm_id: String)

func farm_data(farm: Dictionary) -> void:
	
	print("echas: ", farm)
	%FarmName.text = farm.farmName
	%FarmID.text = farm.id
	%CropType.text = farm.cropType
	%UpdatedAt.text = farm.formattedUpdatedAt
	%CreatedAt.text = farm.formattedCreatedAt
	
	
func _on_farm_button_pressed() -> void:
	on_farm_card_button_pressed.emit(%FarmID.text)
