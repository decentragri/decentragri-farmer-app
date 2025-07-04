extends VBoxContainer

signal forecast_button_pressed




func _on_weather_card_forecast_button_pressed() -> void:
	forecast_button_pressed.emit()
