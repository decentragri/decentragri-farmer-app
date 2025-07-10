extends VBoxContainer

var original_content_container_y: float
var keyboard_is_open: bool = false

func _ready() -> void:
	original_content_container_y = size.y

func _on_farm_profile_container_on_plant_scan_button_pressed(_farm_id: String) -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = true
	visible = true
	reset_fields()


func _process(_delta: float) -> void:
	var keyboard_height: int = DisplayServer.virtual_keyboard_get_height()

	if keyboard_height > 0 and not keyboard_is_open:
		keyboard_is_open = true
		%ContentContainer.size.y = original_content_container_y + keyboard_height
	elif keyboard_height == 0 and keyboard_is_open:
		keyboard_is_open = false
		%ContentContainer.size.y = original_content_container_y


func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()

func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"PlantScanFields"):
		field.text = ""
	%PlantImage.texture = null
