extends Panel

signal forecast_button_pressed

func _ready() -> void:
	%WeatherConditionContainer.visible = false
	Weather.get_current_weather("Camarines Sur")
	connect_signals()
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
	
	if lower_condition.contains("rain") or lower_condition.contains("drizzle"):
		print("Show rain icon")
	elif lower_condition.contains("cloud"):
		print("Show cloud icon")
	elif lower_condition.contains("sun") or lower_condition.contains("clear"):
		print("Show sun icon")
	else:
		print("Show default icon")

		
func _on_forecast_button_pressed() -> void:
	forecast_button_pressed.emit()
