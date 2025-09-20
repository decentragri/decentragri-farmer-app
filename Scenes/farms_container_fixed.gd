extends VBoxContainer

signal on_farm_card_button_pressed(farm_id: String)
signal on_add_farm_button_pressed


var farm_retry_count: int = 0
const MAX_RETRIES: int = 3

const farm_slot: PackedScene = preload("res://Scenes/farm_card.tscn")

func _ready() -> void:
	connect_signal()
	# Load farms (will use cache if available)
	Farm.get_farms()
	

func connect_signal() -> void:
	var _1: int = Farm.get_farms_complete.connect(_on_get_farms_complete)
	
	
func _on_get_farms_complete(farms: Array) -> void:
	if farms.has("error"):
		if farm_retry_count < MAX_RETRIES:
			farm_retry_count += 1
			print("Farm fetch failed. Retrying... (%d/%d)" % [farm_retry_count, MAX_RETRIES])
			Farm.get_farms()
		else:
			print("Farm fetch failed after %d attempts." % MAX_RETRIES)
		return 
	
	# Reset retry count on success
	farm_retry_count = 0
	
	# Clear existing farm cards
	for child: Node in %FarmContainer.get_children():
		child.queue_free()
	
	# Show farms from cache or server
	if farms.size() > 0:
		Utils.logger.info("Displaying %d farms" % farms.size())
		for farm: Dictionary in farms:
			var farm_card: Control = farm_slot.instantiate()
			farm_card.on_farm_card_button_pressed.connect(_on_farm_card_button_pressed)
			farm_card.farm_data(farm)
			%FarmContainer.add_child(farm_card)
	else:
		Utils.logger.info("No farms to display")
	
	# Show cache info for debugging
	var cache_info: Dictionary = Farm.get_cache_info()
	if cache_info.cached_count > 0:
		var cache_age_text: String = "%.1f hours ago" % cache_info.cache_age_hours if cache_info.cache_age_hours > 0 else "just now"
		Utils.logger.info("Cache: %d farms, last updated %s" % [cache_info.cached_count, cache_age_text])
		
	
func _on_farm_card_button_pressed(farm_id: String) -> void:
	on_farm_card_button_pressed.emit(farm_id)
	

func _on_add_farm_button_pressed() -> void:
	on_add_farm_button_pressed.emit()


func refresh_farms() -> void:
	"""Force refresh farms - useful for pull-to-refresh"""
	Utils.logger.info("Refreshing farms...")
	Farm.refresh_farms_cache()
