extends Panel

const seven_day_forecast_slot: PackedScene = preload("res://Scenes/seven_day_forecast_card.tscn")

func _ready() -> void:
	# Clear existing connections to prevent duplicates
	if Weather.get_weather_forecast_complete.is_connected(_on_get_weather_forecast_complete):
		Weather.get_weather_forecast_complete.disconnect(_on_get_weather_forecast_complete)
	
	# Connect the signal
	var _1: int = Weather.get_weather_forecast_complete.connect(_on_get_weather_forecast_complete)
	
	
func _on_get_weather_forecast_complete(weather_forecast: Dictionary) -> void:
	if weather_forecast.has("error"):
		return
	
	# Clear existing forecast cards first
	for child: Control in %ForecastContainer.get_children():
		child.queue_free()
	
	# Add new forecast cards
	for forecast: Dictionary in weather_forecast.forecast.forecastday:
		var seven_day_forecast_card: Control = seven_day_forecast_slot.instantiate()
		seven_day_forecast_card.forecast_data(forecast)
		%ForecastContainer.add_child(seven_day_forecast_card)

# Clean up signal when node exits
func _exit_tree() -> void:
	if Weather.get_weather_forecast_complete.is_connected(_on_get_weather_forecast_complete):
		Weather.get_weather_forecast_complete.disconnect(_on_get_weather_forecast_complete)
