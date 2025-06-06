extends VBoxContainer

const farm_slot: PackedScene = preload("res://Scenes/farm_slot.tscn")

signal _create_farm_button_pressed
signal _on_error_encountered(message: String)
signal _on_farm_data_received(farm_data: Dictionary)


func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Farmer.get_farms_complete.connect(_on_get_farms_complete)
	var _2: int = Farmer.create_farm_complete.connect(_on_create_farm_complete)
	var _3: int = Farmer.get_farm_data_complete.connect(_on_get_farm_data_complete)
	
func _on_get_farms_complete(farms: Array) -> void:
	for farm: Dictionary in farms:
		var farm_slot_instance: Control = farm_slot.instantiate()
		farm_slot_instance.farm_slot_data(farm)
		farm_slot_instance.farm_button_pressed.connect(_on_farm_button_pressed)
		%FarmContainer.add_child(farm_slot_instance)
	
	
func _on_create_farm_button_pressed() -> void:
	_create_farm_button_pressed.emit()
	
	
func _on_visibility_changed() -> void:
	if visible:
		Farmer.get_farms()
	
	
func _on_farm_button_pressed(farm_id: String) -> void:
	Farmer.get_farm_data(farm_id)
	
	
func _on_create_farm_complete(farm_data: Dictionary) -> void:
	if farm_data.has("error"):
		_on_error_encountered.emit(farm_data.error)
	else:
		pass


func _on_get_farm_data_complete(farm_data: Dictionary) -> void:
	if farm_data.has("error"):
		_on_error_encountered.emit(farm_data.error)
	else:
		_on_farm_data_received.emit(farm_data)
