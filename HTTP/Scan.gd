extends Node



var SaveSoilMeterScan: HTTPRequest
var wrSaveSoilMeterScan: WeakRef
signal save_soil_meter_scan_complete(message: Dictionary[String, String])

var GetSoilMeterScan: HTTPRequest
var wrGetSoilMeterScan: WeakRef
signal get_soil_meter_scan_complete(message: Array)


func save_soil_meter_scan(scan_data: Dictionary) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SaveSoilMeterScan = prepared_http_req.request
	wrSaveSoilMeterScan = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = SaveSoilMeterScan.request_completed.connect(_on_SaveSoilMeterScan_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to save soil meter scan")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/save-sensor-readings"

	# Send the GET request using the prepared URL.
	Utils.send_post_request(SaveSoilMeterScan, request_url, scan_data)


func _on_SaveSoilMeterScan_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					save_soil_meter_scan_complete.emit({ "error": json_body.error })
				else:
					print("shit: ", json_body)
					save_soil_meter_scan_complete.emit(json_body)
		else:
			save_soil_meter_scan_complete.emit({ "error": "Unknown server error" })
	else:
		save_soil_meter_scan_complete.emit({ "error": "Unknown server error" })


func get_soil_meter_scan() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetSoilMeterScan = prepared_http_req.request
	wrGetSoilMeterScan = prepared_http_req.weakref

	var _connect: int = GetSoilMeterScan.request_completed.connect(_on_GetSoilMeterScan_request_completed)
	Utils.logger.info("Calling BKMREngine to get soil meter data")
	var request_url: String = Utils.host + "/api/get-sensor-readings"

	# Send the GET request using the prepared URL.
	Utils.send_get_request(GetSoilMeterScan, request_url)
	
	
func _on_GetSoilMeterScan_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_soil_meter_scan_complete.emit({"error": json_body.error})
			else:
				get_soil_meter_scan_complete.emit(json_body)
				print(json_body)
		else:
			get_soil_meter_scan_complete.emit({"error": "Unknown server error"})
	else:
		get_soil_meter_scan_complete.emit({"error": "Unknown server error"})
	
