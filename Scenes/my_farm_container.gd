extends VBoxContainer

const farm_card: PackedScene = preload("res://Scenes/farm_card.tscn")

signal _create_farm_button_pressed
signal _on_error_encountered(message: String)
signal on_button_farm_pressed(farm_id: String)


func _ready() -> void:
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Farm.get_farms_complete.connect(_on_get_farms_complete)
	var _2: int = Farm.create_farm_complete.connect(_on_create_farm_complete)
	
	
func _on_get_farms_complete(farms: Array) -> void:
	for farm: Dictionary in farms:
		var farm_card_instance: Control = farm_card.instantiate()
		farm_card_instance.farm_slot_data(farm)
		farm_card_instance.farm_button_pressed.connect(_on_farm_button_pressed)
		%FarmContainer.add_child(farm_card_instance)
	
	
func _on_create_farm_button_pressed() -> void:
	_create_farm_button_pressed.emit()
	
	
func _on_visibility_changed() -> void:
	if visible:
		Farm.get_farms()
	
	
func _on_farm_button_pressed(farm_id: String) -> void:
	on_button_farm_pressed.emit(farm_id)
	
	
func _on_create_farm_complete(farm_data: Dictionary) -> void:
	if farm_data.has("error"):
		_on_error_encountered.emit(farm_data.error)
	else:
		pass
