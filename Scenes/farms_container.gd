extends VBoxContainer

signal on_farm_card_button_pressed(farm_id: String)
signal on_add_farm_button_pressed


var farm_retry_count: int = 0
const MAX_RETRIES: int = 3

const farm_slot: PackedScene = preload("res://Scenes/farm_card.tscn")

func _ready() -> void:
	connect_signal()
	Farmer.get_farms()
	

func connect_signal() -> void:
	var _1: int = Farmer.get_farms_complete.connect(_on_get_farms_complete)
	
	
func _on_get_farms_complete(farms: Array) -> void:
	if farms.has("error"):
		if farm_retry_count < MAX_RETRIES:
			farm_retry_count += 1
			print("Farm fetch failed. Retrying... (%d/%d)" % [farm_retry_count, MAX_RETRIES])
			Farmer.get_farms()
		else:
			print("Farm fetch failed after %d attempts." % MAX_RETRIES)
		return 
	
	# Reset retry count on success
	farm_retry_count = 0
	
	# Continue populating farm cards
	for farm: Dictionary in farms:
		var farm_card: Control = farm_slot.instantiate()
		farm_card.on_farm_card_button_pressed.connect(_on_farm_card_button_pressed)
		farm_card.farm_data(farm)
		%FarmContainer.add_child(farm_card)
		
	
func _on_farm_card_button_pressed(farm_id: String) -> void:
	on_farm_card_button_pressed.emit(farm_id)
	toggle_container_visibiliy()
	
	
func toggle_container_visibiliy() -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"MainContainers"):
		if "FarmProfile" + "Container" == container.name:
			container.visible = true
		else:
			container.visible = false
	
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu.on_set_botton_menu_buttons_pressed("FarmProfileContainer")


func _on_add_farm_button_pressed() -> void:
	print("tae")
	on_add_farm_button_pressed.emit()
