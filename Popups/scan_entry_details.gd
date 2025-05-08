extends Control

func details_display(data: Dictionary) -> void:
	visible = true

	# Sensor readings with units
	%CropType.text = str(data.get("cropType", "N/A")).capitalize()
	%Fertility.text = str(data.get("fertility", "N/A")) + " µS/cm"
	%Moisture.text = str(data.get("moisture", "N/A")) + " %"
	%PH.text = str(data.get("ph", "N/A"))  # pH is unitless
	%Temperature.text = str(data.get("temperature", "N/A")) + " °C"
	%Sunlight.text = str(data.get("sunlight", "N/A")) + " lux"
	%Humidity.text = str(data.get("humidity", "N/A")) + " %"
	
	var interpretation: Dictionary = data.get("interpretation", {})
	%InterpretationLabel.text = format_interpretation(interpretation)



func format_interpretation(interpretation: Dictionary) -> String:
	if typeof(interpretation) != TYPE_DICTIONARY:
		return "No interpretation data available."

	var formatted: String = ""
	
	var keys: Array[String]= ["fertility", "moisture", "ph", "temperature", "sunlight", "humidity"]
	for key: String in keys:
		if interpretation.has(key):
			formatted += "- " + interpretation[key] + "\n"

	# Add evaluation at the end
	if interpretation.has("evaluation"):
		formatted += "\nOverall Evaluation: " + interpretation["evaluation"]
	
	return formatted
	
	
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		visible = false
