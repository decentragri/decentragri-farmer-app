extends Control

signal _on_error_encountered(message: String)



func _ready() -> void:
    connect_signals()


func connect_signals() -> void:
    var _1: int = Farmer.get_farm_data_complete.connect(_on_get_farm_data_complete)


func get_farm_data(farm_id: String) -> void:
    Farmer.get_farm_data(farm_id)


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




        



func format_js_date(js_date: String) -> String:
    var months: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var dt: Dictionary = Time.get_datetime_dict_from_datetime_string(js_date, true)
    return "%s %d, %d" % [months[dt.month - 1], dt.day, dt.year]


func _on_back_button_pressed() -> void:
    visible = false
