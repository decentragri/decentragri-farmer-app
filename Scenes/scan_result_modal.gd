extends VBoxContainer

func _on_farm_profile_container_farm_scan_card_button_pressed(scan_data: Dictionary) -> void:
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		_show_modal_with_animation(container)
		visible = true
	if scan_data.has("interpretation"):
		%SmoothScrollContainerSoil.visible = true
		%SmoothScrollContainerPlant.visible = false
		display_soil_analysis_result(scan_data)
	else:
		%SmoothScrollContainerSoil.visible = false
		%SmoothScrollContainerPlant.visible = true
		display_plant_scan_result(scan_data)
		
		
func display_plant_scan_result(scan_data: Dictionary) -> void:
	%CropType2.text = scan_data.cropType
	%ScanDate.text = scan_data.formattedCreatedAt
	%ScanID.text = scan_data.id
	%Note.text = scan_data.get("note", "No notes")
	%Diagnosis2.text = scan_data.interpretation.Diagnosis
	%Reason.text = scan_data.interpretation.Reason

	var recs: Array = scan_data.interpretation.Recommendations
	%Recommendations.text = _format_recommendations(recs)
	var image_bytes: PackedByteArray = scan_data.imageBytes
	set_image(image_bytes)
		
	
func display_soil_analysis_result(scan_data: Dictionary) -> void:
	%ID.text = scan_data.id 
	%SensorID.text = scan_data.sensorId
	%CreatedAt.text = scan_data.formattedCreatedAt
	%FarmName.text = scan_data.farmName
	%CropType.text = scan_data.cropType
	%Moisture.text = str(scan_data.moisture) + " %"
	%PH.text = str(scan_data.ph) + " pH"
	%Temperature.text = str(scan_data.temperature) + " °C"
	%Sunlight.text = str(scan_data.sunlight) + " Lux"
	%Humidity.text = str(scan_data.humidity) +  "%"
	%Fertility.text = str(scan_data.fertility) + " µS/cm"
	%SubmittedAt.text = scan_data.formattedSubmittedAt
	
	var interpretation: Dictionary = scan_data.interpretation
	display_interpretation(interpretation)
	
	
func display_interpretation(interpretation: Dictionary) -> void:
	%Evaluation.text = interpretation.evaluation
	%FertilityIntrerpretation.text = interpretation.fertility
	%HumidityInterpretation.text = interpretation.humidity
	%MoistureInterpretation.text = interpretation.moisture
	%PHInterpretation.text = interpretation.ph
	%SunlightInterpretation.text = interpretation.sunlight
	%TemperatureInterpretation.text = interpretation.temperature
	
	
func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		_hide_modal_with_animation(modal_container)
	visible = false


func _show_modal_with_animation(container: VBoxContainer) -> void:
	container.visible = true
	container.modulate.a = 0.0
	var tween: Tween = create_tween()
	var _1: Tween = tween.set_trans(Tween.TRANS_SINE)
	var _2: Tween = tween.set_ease(Tween.EASE_OUT)
	var _3: PropertyTweener = tween.tween_property(container, "modulate:a", 1.0, 0.25)


func _hide_modal_with_animation(container: VBoxContainer) -> void:
	var tween: Tween = create_tween()
	var _1: Tween = tween.set_trans(Tween.TRANS_SINE)
	var _2: Tween = tween.set_ease(Tween.EASE_IN)
	var _3: PropertyTweener = tween.tween_property(container, "modulate:a", 0.0, 0.2)
	var _4: CallbackTweener = tween.tween_callback(Callable(container, "hide"))


func _format_recommendations(recs: Array) -> String:
	if recs.is_empty():
		return "Recommendations:\n  - No recommendations available."

	var lines: Array = []
	for i: int in recs.size():
		var item: String = recs[i]
		lines.append("  %d. %s" % [i + 1, item])
	return "\n".join(lines)


func set_image(image_byte: PackedByteArray) -> void:
	var image: Image = Image.new()
	var error: Error = image.load_png_from_buffer(image_byte)
	if error != OK:
		return
	var plant_scan_image: Texture2D = ImageTexture.create_from_image(image)
	%PlantScanImage.texture = plant_scan_image

	
