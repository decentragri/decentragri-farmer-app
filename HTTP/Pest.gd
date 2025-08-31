extends Node


var SavePestReport: HTTPRequest
var wrSavePestReport: WeakRef
signal save_pest_report_complete(message: Dictionary[String, String])

var GetPestReport: HTTPRequest
var wrGetPestReport: WeakRef
signal get_pest_report_complete(message: Array[Dictionary])


func save_pest_report(pest_data: Dictionary) -> void:
	# Prepare an HTTP request for saving pest report data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SavePestReport = prepared_http_req.request
	wrSavePestReport = prepared_http_req.weakref

	# Log the initiation of the request to save pest report.
	Utils.logger.info("Call to save pest report")
	
	# Construct the request URL for saving pest report data.
	var request_url: String = Utils.host + "/api/save-pest-report"

	# Send the POST request using the prepared URL with retry.
	Utils.send_post_request_with_retry(SavePestReport, request_url, pest_data, _on_SavePestReport_request_completed)


func _on_SavePestReport_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					save_pest_report_complete.emit({ "error": json_body.error })
				else:
					print("Pest report saved successfully: ", json_body)
					save_pest_report_complete.emit(json_body)
		else:
			save_pest_report_complete.emit({ "error": "Unknown server error" })
	else:
		save_pest_report_complete.emit({ "error": "Unknown server error" })


func get_pest_report() -> void:
	# Prepare an HTTP request for fetching pest report data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetPestReport = prepared_http_req.request
	wrGetPestReport = prepared_http_req.weakref

	# Log the initiation of the request to get pest report.
	Utils.logger.info("Call to get pest report")
	
	# Construct the request URL for fetching pest report data.
	var request_url: String = Utils.host + "/api/get-pest-report"

	# Send the GET request using the prepared URL with retry.
	Utils.send_get_request_with_retry(GetPestReport, request_url, _on_GetPestReport_request_completed)


func _on_GetPestReport_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server request was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Array:
				print("Pest reports retrieved successfully: ", json_body.size(), " reports")
				get_pest_report_complete.emit(json_body)
			elif json_body is Dictionary and json_body.has("error"):
				get_pest_report_complete.emit([])
				Utils.logger.error("Error getting pest reports: " + str(json_body.error))
			else:
				get_pest_report_complete.emit([])
				Utils.logger.error("Unexpected response format for pest reports")
		else:
			get_pest_report_complete.emit([])
			Utils.logger.error("Failed to parse pest report response")
	else:
		get_pest_report_complete.emit([])
		Utils.logger.error("Failed to get pest reports from server")
