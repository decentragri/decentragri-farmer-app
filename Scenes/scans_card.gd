extends VBoxContainer


const farm_scan_card: PackedScene = preload("res://Scenes/farm_scan_card.tscn")

signal on_select_scan_button_pressed(button_name: String)

var farm_name: String

func _ready() -> void:
	connect_signals()
	
	

	
	
	
func connect_signals() -> void:
	for button: Button in get_tree().get_nodes_in_group(&"SelectScanButton"):
		var _1: int = button.pressed.connect(_on_select_scan_button_pressed.bind(button))
	var _2: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	var _3: int = Scan.get_plant_scan_complete.connect(_on_get_plan_scan_complete)
	var _4: int = Scan.get_plant_scan_by_farm_complete.connect(_on_get_plan_scan_by_farm_complete)
		
		
func _on_get_plan_scan_by_farm_complete(scan_data: Array) -> void:
	print("bugok: ", scan_data)
	if scan_data.is_empty():
		return
	elif scan_data.has("error"):
		return
	for scan: Dictionary in scan_data:
		print(scan)




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


func _on_visibility_changed() -> void:
	if visible:
		for container: VBoxContainer in get_tree().get_nodes_in_group(&"MainContainers"):
			if container.name == "FarmProfileContainer":
				print("heyss")
				if container.farm_name != "":
					farm_name = container.farm_name
					print("nasan naaa")
					Scan.get_plant_scan_by_farm(farm_name)
			
