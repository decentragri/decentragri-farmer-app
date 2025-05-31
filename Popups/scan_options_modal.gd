extends Control

signal scan_history_button_pressed(button_name: String)


@onready var buttons: Array[TextureButton] = [%PlantScan, %SoilScan]


func _ready() -> void:
	for button: TextureButton in buttons:
		var _1: int = button.pressed.connect(_on_button_pressed.bind(button.name))
		
		
func _on_button_pressed(button_name: String) -> void:
	scan_history_button_pressed.emit(button_name)
	visible = false
	
	
func _on_back_button_pressed() -> void:
	visible = false
