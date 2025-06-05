extends Control


var farm_id: String


func farm_slot_data(farm_data: Dictionary) -> void:
    farm_data.farmId = farm_id
    %FarmName.text = farm_data.farmName
    %CropType.text = farm_data.cropType


    

