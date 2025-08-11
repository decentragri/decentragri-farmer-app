extends Node


var SaveSoilMeterScan: HTTPRequest
var wrSaveSoilMeterScan: WeakRef
signal save_soil_meter_scan_complete(message: Dictionary[String, String])

var SavePlantScan: HTTPRequest
var wrSavePlantScan: WeakRef
signal save_plant_scan_complete(message: Dictionary[String, String])

var GetSoilMeterScan: HTTPRequest
var wrGetSoilMeterScan: WeakRef
signal get_soil_meter_scan_complete(message: Array)

var GetPlantScan: HTTPRequest
var wrGetPlantScan: WeakRef
signal get_plant_scan_complete(message: Array)

var GetPlantScanByFarm: HTTPRequest
var wrGetPlantScanByFarm: WeakRef
signal get_plant_scan_by_farm_complete(message: Array)

var GetSoilAnalysisDataByFarm: HTTPRequest
var wrGetSoilAnalysisDataByFarm: WeakRef
signal get_soil_analysis_data_by_farm_complete(message: Array[Dictionary])



var farm_name: String
var crop_type: String


func save_soil_meter_scan(scan_data: Dictionary) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SaveSoilMeterScan = prepared_http_req.request
	wrSaveSoilMeterScan = prepared_http_req.weakref

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to save soil meter scan")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/save-sensor-readings"

	# Send the POST request using the prepared URL with retry.
	Utils.send_post_request_with_retry(SaveSoilMeterScan, request_url, scan_data, _on_SaveSoilMeterScan_request_completed)


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


func get_soil_analysis_data() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetSoilMeterScan = prepared_http_req.request
	wrGetSoilMeterScan = prepared_http_req.weakref

	Utils.logger.info("Calling to get soil meter data")
	var request_url: String = Utils.host + "/api/get-soil-analysis-data"

	# Send the GET request using the prepared URL with retry.
	Utils.send_get_request_with_retry(GetSoilMeterScan, request_url, _on_GetSoilMeterScan_request_completed)
	
	
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
		else:
			get_soil_meter_scan_complete.emit({"error": "Unknown server error"})
	else:
		get_soil_meter_scan_complete.emit({"error": "Unknown server error"})
	

func save_plant_scan(scan_data: Dictionary) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SavePlantScan = prepared_http_req.request
	wrSavePlantScan = prepared_http_req.weakref

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to save plant scan")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/save-plant-readings"

	# Send the POST request using the prepared URL with retry.
	Utils.send_post_request_with_retry(SavePlantScan, request_url, scan_data, _on_SavePlantScan_request_completed)


func _on_SavePlantScan_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					save_plant_scan_complete.emit({ "error": json_body.error })
				else:
					save_plant_scan_complete.emit(json_body)
		else:
			save_plant_scan_complete.emit({ "error": "Unknown server error" })
	else:
		print(body.get_string_from_utf8())
		print(JSON.parse_string(body.get_string_from_utf8()))
		save_plant_scan_complete.emit({ "error": "Unknown server error" })


func get_plant_scan() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetPlantScan = prepared_http_req.request
	wrGetPlantScan = prepared_http_req.weakref

	Utils.logger.info("Calling to get plant scan data")
	var request_url: String = Utils.host + "/api/get-scan-readings"

	# Send the GET request using the prepared URL with retry.
	Utils.send_get_request_with_retry(GetPlantScan, request_url, _on_GetPlantScan_request_completed)
	
	
func _on_GetPlantScan_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_plant_scan_complete.emit({"error": json_body.error})
			else:
				get_plant_scan_complete.emit(json_body)
		else:
			get_plant_scan_complete.emit({"error": "Unknown server error"})
	else:
		get_plant_scan_complete.emit({"error": "Unknown server error"})
	

func get_plant_scan_by_farm(name_farm: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetPlantScanByFarm = prepared_http_req.request
	wrGetPlantScanByFarm = prepared_http_req.weakref

	Utils.logger.info("Calling to get plant scan data by farm")
	var request_url: String = Utils.host + "/api/get-scan/" + name_farm

	# Send the GET request using the prepared URL with retry.
	Utils.send_get_request_with_retry(GetPlantScanByFarm, request_url, _on_GetPlantScanByFarm_request_completed)
	

func _on_GetPlantScanByFarm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_plant_scan_by_farm_complete.emit({"error": json_body.error})
			else:
				get_plant_scan_by_farm_complete.emit(json_body)
		else:
			get_plant_scan_by_farm_complete.emit({"error": "Unknown server error"})
	else:
		get_plant_scan_by_farm_complete.emit({"error": "Unknown server error"})
	

func get_soil_analysis_data_by_farm(name_farm: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetSoilAnalysisDataByFarm = prepared_http_req.request
	wrGetSoilAnalysisDataByFarm = prepared_http_req.weakref

	Utils.logger.info("Calling to get soil analysis data by farm")
	var request_url: String = Utils.host + "/api/get-soil-analysis-by-farm/" + name_farm

	# Send the GET request using the prepared URL with retry.
	Utils.send_get_request_with_retry(GetSoilAnalysisDataByFarm, request_url, _on_GetSoilAnalysisDataByFarm_request_completed)
	

func _on_GetSoilAnalysisDataByFarm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_soil_analysis_data_by_farm_complete.emit({"error": json_body.error})
			else:
				get_soil_analysis_data_by_farm_complete.emit(json_body)
		else:
			get_soil_analysis_data_by_farm_complete.emit({"error": "Unknown server error"})
	else:
		get_soil_analysis_data_by_farm_complete.emit({"error": "Unknown server error"})
