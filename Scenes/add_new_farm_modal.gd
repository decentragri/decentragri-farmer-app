extends VBoxContainer


func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()
		
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"FarmModalFields"):
		field.text = ""
	%FarmImage.texture = null


func _on_farms_container_on_add_farm_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = true
	visible = true
