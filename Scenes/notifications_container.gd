extends Control


func _on_close_button_pressed() -> void:
	for menu: Control in get_tree().get_nodes_in_group(&"MainMenu"):
		menu._on_notification_button_pressed()
