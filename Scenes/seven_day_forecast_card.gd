extends Control

func forecast_data(day_forecast: Dictionary) -> void:
	# Access the day data with type hints
	var day_data: Dictionary = day_forecast.get("day", {})
	var condition: Dictionary = day_data.get("condition", {})
	
	# Get values with proper types
	var max_temp: float = day_data.get("maxtemp_c", 0.0)
	var min_temp: float = day_data.get("mintemp_c", 0.0)
	var _avg_temp: float = day_data.get("avgtemp_c", 0.0)
	var condition_text: String = condition.get("text", "N/A")
	var humidity: int = day_data.get("avghumidity", 0)
	var wind_speed: float = day_data.get("maxwind_kph", 0.0)
	var rain_chance: int = day_data.get("daily_chance_of_rain", 0)
	var date: String = day_forecast.get("date", "")

	# Update UI elements
	%TemperatureHighLow.text = "%.0f° / %.0f°" % [max_temp, min_temp]
	%Condition.text = condition_text
	%Humidity.text = "%d%%" % humidity
	%WindSpeed.text = "%.0f km/h" % wind_speed
	%RainChance.text = "%d%%" % rain_chance
	%Date.text = date
