extends Panel

signal report_pest_button_pressed


func _on_report_pest_button_pressed() -> void:
	report_pest_button_pressed.emit()
