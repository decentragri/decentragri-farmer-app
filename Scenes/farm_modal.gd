extends Control

const soil_scan_entry_slot: PackedScene = preload("res://Scenes/scan_entry.tscn")
const plant_scan_entry_slot: PackedScene = preload("res://Scenes/plant_scan_entry.tscn")


signal _on_error_encountered(message: String)
signal scan_entry_details_button_pressed(details: Dictionary)


func _ready() -> void:
	connect_signals()


func get_farm_data(farm_id: String) -> void:
	Farmer.get_farm_data(farm_id)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(true , "not bio")
	Scan.get_soil_analysis_data()
	visible = true


func connect_signals() -> void:
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	var _1: int = Farmer.get_farm_data_complete.connect(_on_get_farm_data_complete)
	var _2: int = Scan.get_soil_meter_scan_complete.connect(_on_get_soil_meter_scan_complete)
	var _3: int = Scan.get_plant_scan_complete.connect(_on_get_plan_scan_complete)
	var _4: int  = %ScanButton.pressed.connect(root_node.on_scan_button_pressed)
	config_scan_buttons() 


func _on_get_soil_meter_scan_complete(scan_data: Array) -> void:
	for data: Dictionary in scan_data:
		var scan_entry: Control = soil_scan_entry_slot.instantiate()
		scan_entry.slot_data(data)
		scan_entry.get_node("Panel/ScanDetailsButton").pressed.connect(_on_scan_entry_details_button_pressed.bind(data))
		%ScanEntryContainer.add_child(scan_entry)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node. loading_start(false)


func _on_get_plan_scan_complete(scan_data: Array) -> void:
	for data: Dictionary in scan_data:
		var scan_entry: Control = plant_scan_entry_slot.instantiate()
		scan_entry.slot_data(data)
		scan_entry.get_node("Panel/ScanDetailsButton").pressed.connect(_on_scan_entry_details_button_pressed.bind(data))
		%ScanEntryContainer.add_child(scan_entry)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false)


func _on_scan_entry_details_button_pressed(details: Dictionary) -> void:
	scan_entry_details_button_pressed.emit(details)


func config_scan_buttons() -> void:
	for button: Button in get_tree().get_nodes_in_group("FarmScanButtons"):
		var _1: int = button.pressed.connect(_on_scan_button_pressed.bind(button.name))



func _on_get_farm_data_complete(farm_data: Dictionary) -> void:
	if farm_data.has("error"):
		_on_error_encountered.emit(farm_data.error)
	else:
		display_image(str(farm_data.image))
		%FarmName.text = farm_data.farmName
		%CropType.text = farm_data.cropType

		if farm_data.has("createdAt"):
			%CreatedAt.text = format_js_date(str(farm_data.createdAt))
		if farm_data.has("updatedAt"):
			%UpdatedAt.text = format_js_date(str(farm_data.updatedAt))

		%Owner.text = farm_data.owner
		%Description.text = farm_data.description
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false , "not bio") 
	Scan.farm_name = farm_data.farmName
	Scan.crop_type = farm_data.cropType


func display_image(image_buffer: String) -> void:
	if image_buffer != "":
		var buffer: PackedByteArray = JSON.parse_string(image_buffer)
		var image: Image = Image.new()

		var error: Error = image.load_png_from_buffer(buffer)
		if error != OK:
			_on_error_encountered.emit("Failed to load image from buffer")
			print("Image error code: ", error)
			return

		var farm_pic: Texture2D = ImageTexture.create_from_image(image)
		%FarmPic.texture = farm_pic


func _on_scan_button_pressed(button_name: String) -> void:
	for button: Button in get_tree().get_nodes_in_group("FarmScanButtons"):
		if button.name == button_name:
			button.button_pressed = true
		else:
			button.button_pressed = false
	get_scans(button_name)
	for scan: Control in %ScanEntryContainer.get_children():
		scan.queue_free()
	

func get_scans(button_name: String) -> void:
	print(button_name, " button pressed")
	if not visible:
		return
	match button_name:
		"SoilScan":
			Scan.get_soil_analysis_data()
		"PlantScan":
			Scan.get_plant_scan()
	
	
func format_js_date(js_date: String) -> String:
	var months: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var dt: Dictionary = Time.get_datetime_dict_from_datetime_string(js_date, true)
	return "%s %d, %d" % [months[dt.month - 1], dt.day, dt.year]
	
	
func _on_back_button_pressed() -> void:
	visible = false
