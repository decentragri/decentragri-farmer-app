extends VBoxContainer


const farm_scan_card: PackedScene = preload("res://Scenes/farm_scan_card.tscn")

signal on_select_scan_button_pressed(button_name: String)
signal farm_scan_card_button_pressed(scan_data: Dictionary)

var name_farm: String

func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	for button: Button in get_tree().get_nodes_in_group(&"SelectScanButton"):
		var _1: int = button.pressed.connect(_on_select_scan_button_pressed.bind(button))
	var _2: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	var _3: int = Scan.get_plant_scan_complete.connect(_on_get_plan_scan_complete)
	var _4: int = Scan.get_plant_scan_by_farm_complete.connect(_on_get_plan_scan_by_farm_complete)
	var _5: int = Scan.get_soil_analysis_data_by_farm_complete.connect(_on_get_soil_analysis_data_by_farm_complete)
		
		
func _on_get_plan_scan_by_farm_complete(scan_data: Array) -> void:
	if scan_data.is_empty():
		return
	elif scan_data.has("error"):
		return
	for scan: Dictionary in scan_data:
		var scan_entry: Control = farm_scan_card.instantiate()
		scan_entry.on_farm_scan_card_button_pressed.connect(_on_farm_scan_card_button_pressed)
		scan_entry.slot_data(scan)
		%PlantScanContainer.add_child(scan_entry)
		
	
func _on_farm_scan_card_button_pressed(scan_data: Dictionary) -> void:
	farm_scan_card_button_pressed.emit(scan_data)


func _on_select_scan_button_pressed(button: Button) -> void:
	if button.button_pressed:
		on_select_scan_button_pressed.emit(button.name)
	for button_scan: Button in get_tree().get_nodes_in_group(&"SelectScanButton"):
		if button_scan.name != button.name:
			button_scan.button_pressed = false

	for scan_entry: Control in %PlantScanContainer.get_children():
		scan_entry.queue_free()
	for scan_entry: Control in %SoilAnalysisContainer.get_children():
		scan_entry.queue_free()


	if button.name == "PlantScan":
		Scan.get_plant_scan_by_farm(name_farm)
		%PlantScanContainer.visible = true
		%SoilAnalysisContainer.visible = false
	else:
		Scan.get_soil_analysis_data_by_farm(name_farm)
		%SoilAnalysisContainer.visible = true
		%PlantScanContainer.visible = false

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
	
	
func _on_get_soil_analysis_data_by_farm_complete(scan_data: Array) -> void:
	if scan_data.is_empty():
		return
	elif scan_data.has("error"):
		return
	for scan: Dictionary in scan_data:
		var scan_entry: Control = farm_scan_card.instantiate()
		scan_entry.on_farm_scan_card_button_pressed.connect(_on_farm_scan_card_button_pressed)
		scan_entry.slot_data(scan)
		%SoilAnalysisContainer.add_child(scan_entry)
	
	
func set_farm_name(farm_name: String) -> void:
	name_farm = farm_name
	Scan.get_plant_scan_by_farm(farm_name)
