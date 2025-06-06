extends Control

signal farm_button_pressed(farm_id: String)



func farm_slot_data(farm_data: Dictionary) -> void:
	%FarmName.text = farm_data.farmName 
	%CropType.text = farm_data.cropType
	%FarmButton.pressed.connect(_on_farm_button_pressed.bind(farm_data.id))

	
func _on_farm_button_pressed(farm_id: String) -> void:
	farm_button_pressed.emit(farm_id)
	
