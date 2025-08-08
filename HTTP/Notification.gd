extends Node



var GetNotifications: HTTPRequest
var wrGetNotifications: WeakRef
signal get_notifications_complete(notifications: Array)


func get_notifications(limit: int = 50, offset: int = 0) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetNotifications= prepared_http_req.request
	wrGetNotifications= prepared_http_req.weakref

	var _connect: int = GetNotifications.request_completed.connect(_on_get_notifications_request_completed)
	Utils.logger.info("Calling to get notifications")
	var request_url: String = Utils.host + "/api/notifications"
	request_url += "?limit=" + str(limit) + "&offset=" + str(offset)
	Utils.send_get_request(GetNotifications, request_url)


func _on_get_notifications_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_notifications_complete.emit({"error": json_body.error})
			else:
				get_notifications_complete.emit(json_body.data)
		else:
			get_notifications_complete.emit({"error": "Unknown server error"})
	else:
		get_notifications_complete.emit({"error": "Unknown server error"})
		
