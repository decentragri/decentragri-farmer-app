extends Control

#region 🧾 Details Display

func details_display(data: Dictionary) -> void:
	visible = true

	# Hide all ScanDetailsLabel value and corresponding label pairs first
	for label_node: Label in get_tree().get_nodes_in_group(&"ScanDetailsLabel"):
		label_node.visible = false
		var label_sibling: Label = label_node.get_parent().get_node_or_null("Label")
		if label_sibling:
			label_sibling.visible = false

	# Crop Type
	var crop_type: String = str(data.get("cropType", ""))
	if crop_type.strip_edges() != "":
		%CropType.text = crop_type.capitalize()
		%CropType.visible = true
		var crop_label: Label = %CropType.get_parent().get_node_or_null("Label")
		if crop_label:
			crop_label.visible = true

	# Optional fields with units
	var units: Dictionary[String, String] = {
		"Fertility": " µS/cm",
		"Moisture": " %",
		"PH": "",
		"Temperature": " °C",
		"Sunlight": " lux",
		"Humidity": " %"
	}

	for field: String in units.keys():
		var value: String = str(data.get(field.to_lower(), ""))
		var label_node: Label = get_node_or_null("%" + field)
		if label_node and value.strip_edges() != "":
			label_node.text = value + units[field]
			label_node.visible = true

			var key_label: Label = label_node.get_parent().get_node_or_null("Label")
			if key_label:
				key_label.visible = true

	# Interpretation
	var interpretation: Dictionary
	if data.interpretation is Dictionary:
		interpretation = data.get("interpretation", {})

	%InterpretationLabel.visible = false
	%Reason.visible = false

	var interpretation_label: Label = %InterpretationLabel.get_parent().get_node_or_null("Label")
	var reason_label: Label = %Reason.get_parent().get_node_or_null("Label")

	if interpretation_label:
		interpretation_label.visible = false
	if reason_label:
		reason_label.visible = false

	if typeof(interpretation) == TYPE_DICTIONARY:
		var formatted: String = format_interpretation(interpretation)
		if formatted.strip_edges() != "":
			%InterpretationLabel.text = formatted
			%InterpretationLabel.visible = true
			if interpretation_label:
				interpretation_label.visible = true

		if interpretation.has("Reason"):
			%Reason.text = interpretation["Reason"]
			%Reason.visible = true
			if reason_label:
				reason_label.visible = true

#endregion

#region 🧠 Interpretation Formatting

func format_interpretation(interpretation: Dictionary) -> String:
	var formatted: String = ""
	var keys: Array[String] = ["fertility", "moisture", "ph", "temperature", "sunlight", "humidity"]

	for key: String in keys:
		if interpretation.has(key):
			formatted += "- " + interpretation[key] + "\n"

	if interpretation.has("Diagnosis"):
		formatted = "Diagnosis: " + interpretation["Diagnosis"] + "\n\n" + formatted

	if interpretation.has("evaluation"):
		formatted += "\nOverall Evaluation: " + interpretation["evaluation"]

	if interpretation.has("Recommendations"):
		for r: String in interpretation["Recommendations"]:
			formatted += "- " + str(r) + "\n"

	return formatted.strip_edges()

#endregion

#region 🔙 Navigation & Visibility

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false

func _on_back_button_pressed() -> void:
	visible = false

#endregion
