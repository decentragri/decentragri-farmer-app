extends Panel

signal on_farm_scan_card_button_pressed(scan_data: Dictionary)




func slot_data(scan_data: Dictionary) -> void:
	%FarmScanCardButton.pressed.connect(_on_farm_scan_card_button_pressed.bind(scan_data))
	
	
func _on_farm_scan_card_button_pressed(scan_data: Dictionary) -> void:
	on_farm_scan_card_button_pressed.emit(scan_data)
	
	
	
