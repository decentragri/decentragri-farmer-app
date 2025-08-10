extends Panel




func _ready() -> void:
	Weather.get_weather_forecast("Manila")
	connect_signals()
	
	
func connect_signals() -> void:
	var _1: int = Weather.get_weather_forecast_complete.connect(_on_get_weather_forecast_complete)
	
	
func _on_get_weather_forecast_complete(forecast_data: Dictionary) -> void:
	if forecast_data.has("error"):
		Utils.logger.error("Error getting weather forecast: " + str(forecast_data.error))
		return
	
	
	# Update current weather with type hints
	var current: Dictionary = forecast_data.get("current", {})
	var forecast: Dictionary = {}
	if forecast_data.get("forecast", {}).get("forecastday", []).size() > 0:
		forecast = forecast_data.forecast.forecastday[0]
	
	# Set location
	%Region.text = forecast_data.location.region
	%Date.text = forecast_data.forecast.forecastday[0].date
	
	# Set current conditions
	if current.has("condition"):
		var condition_text: String = str(current.condition.get("text", ""))
		%Condition.text = condition_text
		get_weather_icon(condition_text)
	
	if current.has("temp_c"):
		%Temperature.text = "%.1f°C" % current.temp_c
	
	if current.has("humidity"):
		%Humidity.text = "%d%%" % current.humidity
	
	if current.has("wind_kph"):
		%WindSpeed.text = "%.1f km/h" % current.wind_kph
	
	if current.has("chance_of_rain"):
		%RainChance.text = "%d%%" % current.chance_of_rain
	
	# Set high/low temperatures from today's forecast if available
	var forecast_day: Dictionary = forecast.get("day", {}) if forecast else {}
	if forecast_day:
		%TempratureHighLow.text = "%.1f°C / %.1f°C" % [
			forecast_day.get("maxtemp_c", 0.0), 
			forecast_day.get("mintemp_c", 0.0)
		]
	
	
func get_weather_icon(condition: String) -> void:
	var lower_condition: String = condition.to_lower()
	
	var cloudy_icon: Texture = preload("res://Assets/Icons/cloudy_icon_white.png")
	var rainy_icon: Texture = preload("res://Assets/Icons/rain_icon_white.png")
	var sunny_icon: Texture = preload("res://Assets/Icons/sunny_white_icon.png")
	
	if lower_condition.contains("rain") or lower_condition.contains("drizzle"):
		%WeatherIcon.texture = rainy_icon
	elif lower_condition.contains("cloud"):
		%WeatherIcon.texture = cloudy_icon
	elif lower_condition.contains("sun") or lower_condition.contains("clear"):
		%WeatherIcon.texture = sunny_icon
	else:
		%WeatherIcon.texture = sunny_icon
