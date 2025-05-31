extends Control




func slot_data(data: Dictionary) -> void:
	var created_at: String = data.createdAt
	set_time_date(created_at)
	if data.has("interpretation") and typeof(data["interpretation"]) == TYPE_DICTIONARY and data["interpretation"].has("Diagnosis"):
		%Diagnosis.text = data["interpretation"]["Diagnosis"]
	else:
		%Diagnosis.text = "No evaluation"
		
	var crop_type: String = data.cropType
	%CropLabel.text = crop_type.capitalize()
	
	
func set_time_date(created_at: String) -> void:
	if created_at == "":
		%DateLabel.text = "No date"
		return
	var iso_date: String = created_at
	if iso_date == "":
		%DateLabel.text = "No date"
		return

	# Parse datetime string
	var dt: Dictionary = Time.get_datetime_dict_from_datetime_string(iso_date, false)
	var unix_time: int = Time.get_unix_time_from_datetime_dict(dt)

	# Adjust for Philippine Time (UTC+8)
	var unix_ph_time : int = unix_time + (8 * 3600)
	var local_dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_ph_time)

	var month_names: Array[String] = [
		"", "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	]

	var month_name: String = month_names[local_dt.month]

	# Format hour to 12-hour format
	var hour: int = local_dt.hour % 12
	if hour == 0:
		hour = 12
	var minute: String = "%02d" % local_dt.minute
	var meridian: String = "am" if local_dt.hour < 12 else "pm"

	var formatted_date: String = "%s %d, %d - %d:%s%s" % [
		month_name, local_dt.day, local_dt.year, hour, minute, meridian
	]
	%DateLabel.text = formatted_date
