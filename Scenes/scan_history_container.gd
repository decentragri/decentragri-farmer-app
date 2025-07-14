extends VBoxContainer

signal scan_entry_details_button_pressed(details: Dictionary)

var soil_scan_entry_slot: PackedScene = preload("res://Scenes/scan_entry.tscn")
var plant_scan_entry_slot: PackedScene = preload("res://Scenes/plant_scan_entry.tscn")



func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	var _2: int = Scan.get_plant_scan_complete.connect(_on_get_plan_scan_complete)

func set_history_mode(history: String) -> void:
	match history:
		"SoilScan":
			Scan.get_soil_analysis_data()
		"PlantScan":
			print("tae")
			Scan.get_plant_scan()
	visible = true
	
func _on_visibility_changed() -> void:
	if visible:
		pass

	else:
		for child: Control in %ScanEntryContainer.get_children():
			child.queue_free()
	
	
func _on_get_soil_meter_scan_complete(scan_data: Array) -> void:
	for data: Dictionary in scan_data:
		var scan_entry: Control = soil_scan_entry_slot.instantiate()
		scan_entry.slot_data(data)
		scan_entry.get_node("Panel/ScanDetailsButton").pressed.connect(_on_scan_entry_details_button_pressed.bind(data))
		%ScanEntryContainer.add_child(scan_entry)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node. loading_start(false)
	
	
func _on_get_plan_scan_complete(scan_data: Array) -> void:
	for data: Dictionary in scan_data:
		var scan_entry: Control = plant_scan_entry_slot.instantiate()
		scan_entry.slot_data(data)
		scan_entry.get_node("Panel/ScanDetailsButton").pressed.connect(_on_scan_entry_details_button_pressed.bind(data))
		%ScanEntryContainer.add_child(scan_entry)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node. loading_start(false)
	
	
func _on_scan_entry_details_button_pressed(details: Dictionary) -> void:
	scan_entry_details_button_pressed.emit(details)
	
