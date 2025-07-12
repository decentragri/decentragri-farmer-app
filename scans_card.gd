extends VBoxContainer


const farm_scan_card: PackedScene = preload("res://Scenes/farm_scan_card.tscn")

signal on_select_scan_button_pressed(button_name: String)


func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	for button: Button in get_tree().get_nodes_in_group(&"SelectScanButton"):
		var _1: int = button.pressed.connect(_on_select_scan_button_pressed.bind(button))
	var _2: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	var _3: int = Scan.get_plant_scan_complete.connect(_on_get_plan_scan_complete)
		
		
func _on_select_scan_button_pressed(button: Button) -> void:
	if button.button_pressed:
		on_select_scan_button_pressed.emit(button.name)
	for button_scan: Button in get_tree().get_nodes_in_group(&"SelectScanButton"):
		if button_scan.name != button.name:
			button_scan.button_pressed = false


func _on_get_soil_meter_scan_complete(scan_data: Array) -> void:
	if scan_data.is_empty():
		return
	for scan: Dictionary in scan_data:
		var scan_entry: Control = farm_scan_card.instantiate()
		scan_entry.slot_data(scan)
		%SoilAnalysisContainer.add_child(scan_entry)


func _on_get_plan_scan_complete(scan_data: Array) -> void:
	if scan_data.is_empty():
		return
	for scan: Dictionary in scan_data:
		var scan_entry: Control = farm_scan_card.instantiate()
		scan_entry.slot_data(scan)
		%PlantScanContainer.add_child(scan_entry)
