extends VBoxContainer


func _on_farm_profile_container_on_plant_scan_button_pressed(_farm_id: String) -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		container.visible = true
	visible = true
	reset_fields()
	
	
func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()

func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"PlantScanFields"):
		field.text = ""
	%PlantImage.texture = null
