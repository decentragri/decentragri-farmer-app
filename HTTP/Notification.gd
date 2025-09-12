extends Node

# HTTP Request variables (following your existing pattern)
var GetNotifications: HTTPRequest
var wrGetNotifications: WeakRef
var GetBadgeStatus: HTTPRequest
var wrGetBadgeStatus: WeakRef
var MarkPanelViewed: HTTPRequest
var wrMarkPanelViewed: WeakRef
var MarkNotificationRead: HTTPRequest
var wrMarkNotificationRead: WeakRef

# Signals for completion of API calls
signal get_notifications_complete(notifications: Array)
signal get_badge_status_complete(badge_data: Dictionary)
signal mark_notification_read_complete(success: bool)
signal mark_panel_viewed_complete(success: bool)

# EXISTING: Get notifications (keeping your original implementation)
func get_notifications(limit: int = 50, offset: int = 0) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetNotifications = prepared_http_req.request
	wrGetNotifications = prepared_http_req.weakref
	
	Utils.logger.info("Calling to get notifications")
	var request_url: String = Utils.host + "/api/notifications"
	request_url += "?limit=" + str(limit) + "&offset=" + str(offset)
	Utils.send_get_request_with_retry(GetNotifications, request_url, _on_get_notifications_request_completed)

# EXISTING: Handle notifications response (keeping your original implementation)
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
		get_notifications_complete.emit([])

# NEW: Get badge status (correct YouTube/Facebook behavior)
func get_badge_status() -> void:
	# Prepare an HTTP request following your pattern
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetBadgeStatus = prepared_http_req.request
	wrGetBadgeStatus = prepared_http_req.weakref
	
	Utils.logger.info("Calling to get badge status")
	var request_url: String = Utils.host + "/api/notifications/badge-correct"
	Utils.send_get_request_with_retry(GetBadgeStatus, request_url, _on_get_badge_status_request_completed)

# NEW: Handle badge status response
func _on_get_badge_status_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_badge_status_complete.emit({"error": json_body.error})
			else:
				get_badge_status_complete.emit(json_body)
		else:
			get_badge_status_complete.emit({"error": "Unknown server error"})
	else:
		get_badge_status_complete.emit({"showBadge": false, "count": 0})

# NEW: Mark panel as viewed (bell icon click)
func mark_panel_as_viewed() -> void:
	# Prepare an HTTP request following your pattern
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	MarkPanelViewed = prepared_http_req.request
	wrMarkPanelViewed = prepared_http_req.weakref
	
	Utils.logger.info("Marking notification panel as viewed")
	var request_url: String = Utils.host + "/api/notifications/panel-viewed"
	Utils.send_patch_request_with_retry(MarkPanelViewed, request_url, {}, _on_mark_panel_viewed_request_completed)
	
	
# NEW: Handle panel viewed response
func _on_mark_panel_viewed_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		Utils.logger.info("Notification panel marked as viewed successfully")
		mark_panel_viewed_complete.emit(true)
		# Optionally refresh badge status after marking panel as viewed
		get_badge_status()
	else:
		Utils.logger.error("Failed to mark notification panel as viewed")
		mark_panel_viewed_complete.emit(false)

# NEW: Mark individual notification as read
func mark_notification_as_read(notification_id: String) -> void:
	# Prepare an HTTP request following your pattern
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	MarkNotificationRead = prepared_http_req.request
	wrMarkNotificationRead = prepared_http_req.weakref
	
	Utils.logger.info("Marking notification as read: " + notification_id)
	var request_url: String = Utils.host + "/api/notifications/" + notification_id + "/read"
	Utils.send_patch_request_with_retry(MarkNotificationRead, request_url, {}, _on_mark_notification_read_request_completed)

# NEW: Handle mark notification as read response
func _on_mark_notification_read_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		Utils.logger.info("Notification marked as read successfully")
		mark_notification_read_complete.emit(true)
		# Optionally refresh badge status after marking notification as read
		get_badge_status()
	else:
		Utils.logger.error("Failed to mark notification as read")
		mark_notification_read_complete.emit(false)
