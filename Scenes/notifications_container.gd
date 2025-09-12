# Updated Notification Container with CORRECT YouTube/Facebook Badge Behavior
extends Control

var notification_card_slot: PackedScene = preload("res://Scenes/notification_card.tscn")
# Dictionary to track existing notification IDs
var existing_notifications: Dictionary = {}

var first_fetch: bool = false

# Signal for badge updates (NEW - uses correct behavior)
signal badge_updated(show_badge: bool, count_text: String)
# Signal for unread count updates (LEGACY - for compatibility)
signal unread_count_updated(count_text: String)

func _ready() -> void:
	init_get_notifications()
	init_get_badge_status()  # NEW: Initialize badge checking
	connect_signals()

func init_get_notifications() -> void:
	Notification.get_notifications()
	var _1: int = get_tree().create_timer(10.0).timeout.connect(init_get_notifications)

# NEW: Initialize badge status checking
func init_get_badge_status() -> void:
	Notification.get_badge_status()
	var _2: int = get_tree().create_timer(5.0).timeout.connect(init_get_badge_status)  # Check more frequently

func connect_signals() -> void:
	var _1: int = Notification.get_notifications_complete.connect(_on_get_notifications_complete)
	var _2: int = Notification.get_badge_status_complete.connect(_on_get_badge_status_complete)  # NEW

func _on_get_notifications_complete(notifications: Array) -> void:
	if first_fetch == false:
		notifications.reverse()
		first_fetch = true
		
	var unread_count: int = 0
	
	for notif: Dictionary in notifications:
		var notification_id: String = notif.get("id", "")
		var is_read: bool = notif.get("read", false)
		
		# Count unread notifications (for legacy compatibility)
		if not is_read:
			unread_count += 1
		
		# Check if this notification already exists
		if existing_notifications.has(notification_id):
			# Find the existing notification card and update its data
			for child: Panel in %NotificationsContainer.get_children():
				if child.has_meta("notification_id") and child.get_meta("notification_id") == notification_id:
					child.slot_data(notif)  # Update the existing card with new data (including timeAgo)
					break
			continue
			
		# Create new notification card for new notifications
		var notification_slot: Panel = notification_card_slot.instantiate()
		notification_slot.set_meta("notification_id", notification_id)
		%NotificationsContainer.add_child(notification_slot)
		%NotificationsContainer.move_child(notification_slot, 0)
		notification_slot.slot_data(notif)
		
		# Connect the notification click signal
		if notification_slot.has_signal("notification_clicked"):
			var _3: int = notification_slot.notification_clicked.connect(_on_notification_clicked)
		
		# Track this notification as existing
		existing_notifications[notification_id] = true
	
	# Emit legacy unread count signal for backward compatibility
	_emit_unread_count(unread_count)

# NEW: Handle badge status from the correct API
func _on_get_badge_status_complete(badge_data: Dictionary) -> void:
	var show_badge: bool = badge_data.get("showBadge", false)
	var count: int = badge_data.get("count", 0)
	
	var count_text: String = _format_badge_count(count)
	
	# Emit the NEW badge signal
	badge_updated.emit(show_badge, count_text)
	
	# Also emit legacy signal for backward compatibility
	if show_badge:
		unread_count_updated.emit(count_text)
	else:
		unread_count_updated.emit("")

# NEW: Handle notification clicks (mark individual notifications as read)
func _on_notification_clicked(notification_id: String) -> void:
	Notification.mark_notification_as_read(notification_id)
	
	# Update the notification in our tracking
	for child: Panel in %NotificationsContainer.get_children():
		if child.has_meta("notification_id") and child.get_meta("notification_id") == notification_id:
			# Update the visual state to show as read
			if child.has_method("mark_as_read"):
				child.mark_as_read()
			break

# NEW: Handle bell icon click (YouTube/Facebook behavior)
func _on_bell_icon_clicked() -> void:
	# Mark panel as viewed - this hides the badge but keeps notifications unread
	Notification.mark_panel_as_viewed()
	
	# Immediately hide the badge (don't wait for next API call)
	badge_updated.emit(false, "")
	unread_count_updated.emit("")  # Legacy compatibility

func _format_badge_count(count: int) -> String:
	if count == 0:
		return ""  # No badge shown for 0 unread
	elif count <= 10:
		return str(count)  # Show exact count: "1", "2", "10"
	else:
		return "10+"  # Show "10+" for anything over 10

# LEGACY: Emit unread count signal (for backward compatibility)
func _emit_unread_count(count: int) -> void:
	var count_text: String = _format_badge_count(count)
	unread_count_updated.emit(count_text)

func _on_close_button_pressed() -> void:
	# This is when the panel closes - mark as viewed
	_on_bell_icon_clicked()
	
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu._on_notification_button_pressed()

# Optional: Function to remove a notification (e.g., when marked as read)
func remove_notification(notification_id: String) -> void:
	# Remove from tracking dictionary
	if existing_notifications.has(notification_id):
		var _1: bool = existing_notifications.erase(notification_id)
	
	# Find and remove the UI element
	for child: Panel in %NotificationsContainer.get_children():
		if child.has_meta("notification_id") and child.get_meta("notification_id") == notification_id:
			child.queue_free()
			break
	
	# Refresh badge status from server
	Notification.get_badge_status()

# Optional: Clear all notifications (useful for logout or refresh)
func clear_all_notifications() -> void:
	existing_notifications.clear()
	for child: Panel in %NotificationsContainer.get_children():
		child.queue_free()
	
	# Emit zero count
	badge_updated.emit(false, "")
	unread_count_updated.emit("")  # Legacy compatibility

# Helper function to refresh badge status manually
func refresh_badge_status() -> void:
	Notification.get_badge_status()
