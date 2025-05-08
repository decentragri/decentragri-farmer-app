extends VBoxContainer

signal scan_entry_details_button_pressed(details: Dictionary)

var scan_entry_slot: PackedScene = preload("res://Scenes/scan_entry.tscn")



func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	
	
func _on_visibility_changed() -> void:
	if visible:
		Scan.get_soil_meter_scan()
	else:
		for child: Control in %ScanEntryContainer.get_children():
			child.queue_free()
	
	
func _on_get_soil_meter_scan_complete(scan_data: Array) -> void:
	for data: Dictionary in scan_data:
		var scan_entry: Control = scan_entry_slot.instantiate()
		scan_entry.slot_data(data)
		scan_entry.get_node("Panel/ScanDetailsButton").pressed.connect(_on_scan_entry_details_button_pressed.bind(data))
		%ScanEntryContainer.add_child(scan_entry)
		
	
func _on_scan_entry_details_button_pressed(details: Dictionary) -> void:
	scan_entry_details_button_pressed.emit(details)
	
