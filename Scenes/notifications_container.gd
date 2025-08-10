extends Control

var notification_card_slot: PackedScene = preload("res://Scenes/notification_card.tscn")
# Dictionary to track existing notification IDs
var existing_notifications: Dictionary = {}

var first_fetch: bool = false

# Signal for unread count updates
signal unread_count_updated(count_text: String)

func _ready() -> void:
	init_get_notifications()
	connect_signals()
	
	
func init_get_notifications() -> void:
	Notification.get_notifications()
	var _1: int = get_tree().create_timer(10.0).timeout.connect(init_get_notifications)
	

func connect_signals() -> void:
	var _1: int = Notification.get_notifications_complete.connect(_on_get_notifications_complete)


func _on_get_notifications_complete(notifications: Array) -> void:
	if first_fetch == false:
		notifications.reverse()
		first_fetch = true
		
	var unread_count: int = 0
	
	for notif: Dictionary in notifications:
		var notification_id: String = notif.get("id", "")
		var is_read: bool = notif.get("read", false)
		
		# Count unread notifications
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
		
		# Track this notification as existing
		existing_notifications[notification_id] = true
	
	# Emit unread count signal
	_emit_unread_count(unread_count)


func _emit_unread_count(count: int) -> void:
	var count_text: String
	
	if count == 0:
		count_text = ""  # No badge shown for 0 unread
	elif count <= 10:
		count_text = str(count)  # Show exact count: "1", "2", "10"
	else:
		count_text = "10+"  # Show "10+" for anything over 10
	
	unread_count_updated.emit(count_text)


func _on_close_button_pressed() -> void:
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
	
	# Refresh unread count after removal
	_refresh_unread_count()


# Optional: Clear all notifications (useful for logout or refresh)
func clear_all_notifications() -> void:
	existing_notifications.clear()
	for child: Panel in %NotificationsContainer.get_children():
		child.queue_free()
	
	# Emit zero count
	unread_count_updated.emit("")


# Helper function to refresh unread count manually
func _refresh_unread_count() -> void:
	var unread_count: int = 0
	
	for child: Panel in %NotificationsContainer.get_children():
		# Assuming your notification card has a way to check if it's read
		# You might need to adjust this based on your notification card implementation
		if child.has_method("is_unread") and child.is_unread():
			unread_count += 1
	
	_emit_unread_count(unread_count)
