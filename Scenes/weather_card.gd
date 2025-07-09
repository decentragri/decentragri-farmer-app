extends Panel

signal forecast_button_pressed

func _ready() -> void:
	connect_signals()
	initialize_config()
	
func initialize_config() -> void:
	Weather.get_current_weather("Camarines Sur")
	%WeatherConditionContainer.visible = false
	
	%LoaderContainer.visible = true
	%TextureProgressBar.play()
	%Button.mouse_filter = MOUSE_FILTER_IGNORE
	
	
func connect_signals() -> void:
	var _1: int = Weather.get_current_weather_complete.connect(_on_get_current_weather_complete)
	
	
func _on_get_current_weather_complete(current_weather: Dictionary) -> void:
	if current_weather.has("error"):
		return
	
	var condition: String = current_weather.current.condition.text
	%Region.text = current_weather.location.region
	%Condition.text = condition
	%Temperature.text = str(current_weather.current.temp_c) + "°C"
	%Humidity.text = str(current_weather.current.humidity) + "%"
	%WindSpeed.text = str(current_weather.current.wind_kph) + "km/h"
	
	get_weather_icon(condition)
	%LoaderContainer.visible = false
	%WeatherConditionContainer.visible = true
	%TextureProgressBar.stop()
	
	
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

		
func _on_forecast_button_pressed() -> void:
	forecast_button_pressed.emit()
