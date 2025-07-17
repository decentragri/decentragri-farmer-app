extends Panel

signal on_farm_scan_card_button_pressed(scan_data: Dictionary)



func slot_data(scan_data: Dictionary) -> void:
	if scan_data.has("diagnosis"):
		%PlantScanContainer.visible = true
		%"SoilAnalysisContainer".visible = false
		
		%Diagnosis.text = "Diagnosis: " + scan_data.interpretation.Diagnosis
		%CropType.text = "Crop: " + scan_data.cropType
		%Date.text = "Date: " +  scan_data.formattedCreatedAt
		%ID.text = "ID: " + scan_data.id
	elif scan_data.has("interpretation"):
		%"SoilAnalysisContainer".visible = true
		%PlantScanContainer.visible = false
		
		%Evaluation.text = "Evaluaton: " + scan_data.interpretation.evaluation
		%CropType2.text = "Crop: " + scan_data.cropType
		%Date2.text = "Date: " + scan_data.createdAt
		%ID2.text = "ID: " + scan_data.id
	%FarmScanCardButton.pressed.connect(_on_farm_scan_card_button_pressed.bind(scan_data))
	
	
func _on_farm_scan_card_button_pressed(scan_data: Dictionary) -> void:
	on_farm_scan_card_button_pressed.emit(scan_data)
	
