extends Node


var GetCurrentWeather: HTTPRequest
var wrCurrentWeather: WeakRef
signal get_current_weather_complete(message: Dictionary)

var GetWeatherIcon: HTTPRequest
var wrGetWeatherIcon: WeakRef
signal get_weather_icon_complete(image: Dictionary[String, Texture])


func get_current_weather(location: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetCurrentWeather = prepared_http_req.request
	wrCurrentWeather = prepared_http_req.weakref

	var _connect: int = GetCurrentWeather.request_completed.connect(_on_GetCurrentWeather_request_completed)
	Utils.logger.info("Calling BKMREngine to get prices")
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
func get_weather_icon(icon_uri: String) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetWeatherIcon = prepared_http_req.request
	wrGetWeatherIcon = prepared_http_req.weakref

	var _connect: int = GetWeatherIcon.request_completed.connect(_on_GetWeatherIcon_request_completed)
	Utils.logger.info("Calling BKMREngine to get prices")
	var request_url: String = "https://" + icon_uri.replace("//", "")
	
	Utils.send_get_request(GetWeatherIcon, request_url)
	
	
func _on_GetWeatherIcon_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	if response_code == 200:
		var image: Image = Image.new()
		var load_result: Error = image.load_png_from_buffer(body)
		if load_result == OK:
			var texture: Texture = ImageTexture.create_from_image(image)
			get_weather_icon_complete.emit({"texture": texture})
		else:
			get_weather_icon_complete.emit({"error": "Failed to decode image"})
	else:
		get_weather_icon_complete.emit({"error": "HTTP Error: %d" % response_code})

		
