extends Node


var GetCurrentWeather: HTTPRequest
var wrCurrentWeather: WeakRef
signal get_current_weather_complete(message: Dictionary)


var GetWeatherForecast: HTTPRequest
var wrGetWeatherForecast: WeakRef
# Emitted when weather forecast data is received
# @param forecast_data: Dictionary containing the forecast data matching the ForecastData interface
signal get_weather_forecast_complete(forecast_data: Dictionary)




func get_current_weather(location: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetCurrentWeather = prepared_http_req.request
	wrCurrentWeather = prepared_http_req.weakref

	var _connect: int = GetCurrentWeather.request_completed.connect(_on_GetCurrentWeather_request_completed)
	Utils.logger.info("Calling  to get weather")
	var request_url: String = Utils.host + "/api/weather/current/" + location
	Utils.send_get_request(GetCurrentWeather, request_url)
	
	
func _on_GetCurrentWeather_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_current_weather_complete.emit({"error": json_body.error})
			else:
				get_current_weather_complete.emit(json_body)
		else:
			get_current_weather_complete.emit({"error": "Unknown server error"})
	else:
		get_current_weather_complete.emit({"error": "Unknown server error"})
		

#//cdn.weatherapi.com/weather/64x64/night/176.png


		
func get_weather_forecast(location: String) -> void:
	# Prepare an HTTP request for fetching weather forecast data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetWeatherForecast = prepared_http_req.request
	wrGetWeatherForecast = prepared_http_req.weakref

	var _connect: int = GetWeatherForecast.request_completed.connect(_on_GetWeatherForecast_request_completed)
	Utils.logger.info("Calling to get weather forecast")
	var request_url: String = Utils.host + "/api/weather/forecast/" + location
	Utils.send_get_request(GetWeatherForecast, request_url)
	
func _on_GetWeatherForecast_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_weather_forecast_complete.emit({"error": json_body.error})
			else:
				# Process the forecast data to match the expected structure
				var forecast_data: Dictionary = {
					"location": json_body.get("location", {}),
					"current": json_body.get("current", {}),
					"forecast": {
						"forecastday": json_body.get("forecast", {}).get("forecastday", [])
					}
				}
				get_weather_forecast_complete.emit(forecast_data)
		else:
			get_weather_forecast_complete.emit({"error": "Failed to parse server response"})
	else:
		get_weather_forecast_complete.emit({"error": "HTTP request failed with status: %d" % response_code})
	
