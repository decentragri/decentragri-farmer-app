# Updated Individual Notification Card with Click Handling
extends Panel

# Signal emitted when this notification is clicked
signal notification_clicked(notification_id: String)

var notification_data: Dictionary = {}
var is_read: bool = false

func slot_data(data: Dictionary) -> void:
	notification_data = data
	is_read = data.get("read", false)
	
	%Message.text = data.message
	%TimeAgo.text = data.timeAgo + " ago"
	
	# Update visual appearance based on read status
	_update_visual_state()

func _update_visual_state() -> void:
	# Update the visual state based on read/unread status
	if is_read:
		# Style for read notifications (e.g., lighter background, different text color)
		modulate = Color(0.8, 0.8, 0.8, 1.0)  # Dimmed
		# You can also change background color, font color, etc.
	else:
		# Style for unread notifications (e.g., normal background, bold text)
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func mark_as_read() -> void:
	is_read = true
	notification_data["read"] = true
	_update_visual_state()

func is_unread() -> bool:
	return not is_read

# Handle clicks on the notification
func _on_notification_clicked() -> void:
	var notification_id: String = notification_data.get("id", "")
	if notification_id != "":
		# Emit signal to parent container
		notification_clicked.emit(notification_id)
		
		# Mark this notification as read locally
		mark_as_read()


func _on_button_pressed() -> void:
	_on_notification_clicked()
