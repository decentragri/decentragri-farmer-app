extends Node

var CreateFarm: HTTPRequest
var wrCreateFarm: WeakRef
signal create_farm_complete(message: Dictionary[String, String])

var GetFarms: HTTPRequest
var wrGetFarms: WeakRef
signal get_farms_complete(farm: Array[Dictionary])

var GetFarmData: HTTPRequest
var wrGetFarmData: WeakRef
signal get_farm_data_complete(farm: Dictionary)

var SellFarm: HTTPRequest
var wrSellFarm: WeakRef
signal sell_farm_complete(message: Dictionary[String, String])


func create_farm(farm_data: Dictionary[String, Variant]) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	CreateFarm = prepared_http_req.request
	wrCreateFarm = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = CreateFarm.request_completed.connect(_on_create_farm_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to create farm")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/create/farm"

	# Send the GET request using the prepared URL.
	Utils.send_post_request(CreateFarm, request_url, farm_data)


func _on_create_farm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					create_farm_complete.emit({ "error": json_body.error })
				else:
					create_farm_complete.emit(json_body)
		else:
			create_farm_complete.emit({ "error": "Unknown server error" })
	else:
		create_farm_complete.emit({ "error": "Unknown server error" })
		
		
		
func get_farms() -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetFarms = prepared_http_req.request
	wrGetFarms = prepared_http_req.weakref

	var _connect: int = GetFarms.request_completed.connect(_on_get_farms_request_completed)
	Utils.logger.info("Call to get farms")
	
	var request_url: String = Utils.host + "/api/list/farm"
	Utils.send_get_request(GetFarms, request_url)


func _on_get_farms_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			
			if json_body.has("error"):
				get_farms_complete.emit({ "error": json_body.error })
			else:
				get_farms_complete.emit(json_body)
		else:
			get_farms_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		print("error: ", json_body)
		get_farms_complete.emit([])


func get_farm_data(farm_id: String) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetFarmData = prepared_http_req.request
	wrGetFarmData = prepared_http_req.weakref

	var _connect: int = GetFarmData.request_completed.connect(_on_get_farm_data_request_completed)
	Utils.logger.info("Call to get farm data")
	
	var request_url: String = Utils.host + "/api/data/farm/" + farm_id
	Utils.send_get_request(GetFarmData, request_url)


func _on_get_farm_data_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:	
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_farm_data_complete.emit({ "error": json_body.error })
			else:
				get_farm_data_complete.emit(json_body)
		else:
			get_farm_data_complete.emit({ "error": "Unknown server error" })
	else:
		get_farm_data_complete.emit({ "error": "Unknown server error" })


func sell_farm(farm_id: String) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SellFarm = prepared_http_req.request
	wrSellFarm = prepared_http_req.weakref

	var _connect: int = SellFarm.request_completed.connect(_on_sell_farm_request_completed)
	Utils.logger.info("Call to sell farm")
	
	var request_url: String = Utils.host + "/api/sell/farm/" + farm_id
	Utils.send_post_request(SellFarm, request_url, {})
	
	
func _on_sell_farm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:	
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				sell_farm_complete.emit({ "error": json_body.error })
			else:
				sell_farm_complete.emit(json_body)
		else:
			sell_farm_complete.emit({ "error": "Unknown server error" })
	else:
		sell_farm_complete.emit({ "error": "Unknown server error" })
