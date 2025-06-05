extends Control

signal farm_button_pressed(farm_id: String)

var farm_id: String


func farm_slot_data(farm_data: Dictionary) -> void:
    farm_data.farmId = farm_id
    %FarmName.text = farm_data.farmName
    %CropType.text = farm_data.cropType


    
func _on_farm_button_pressed() -> void:
    farm_button_pressed.emit(farm_id)
	
