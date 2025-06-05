extends VBoxContainer
signal _create_farm_button_pressed

const farm_slot: PackedScene = preload("res://Scenes/farm_slot.tscn")



func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _1: int = Farmer.get_farms_complete.connect(_on_get_farms_complete)


func _on_get_farms_complete(farms: Array) -> void:
	print("Farms received: ", farms)
	for farm: Dictionary in farms:
		var farm_slot_instance: Control = farm_slot.instantiate()
		farm_slot_instance.farm_id = farm.id
		farm_slot_instance.farm_slot_data(farm)
		%FarmContainer.add_child(farm_slot_instance)


func _on_create_farm_button_pressed() -> void:
	_create_farm_button_pressed.emit()



func _on_visibility_changed() -> void:
	if visible:
		Farmer.get_farms()
