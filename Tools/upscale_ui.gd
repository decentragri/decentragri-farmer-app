extends Node

const SCALE_FACTOR: float = 1.5

func _ready() -> void:
	var dir: DirAccess = DirAccess.open("res://")
	if not dir:
		push_error("Failed to open project directory")
		return
	
	# Create backup directory
	var backup_dir: String = "res://backups/"
	if not DirAccess.dir_exists_absolute(backup_dir):
		var _1: int = dir.make_dir_recursive(backup_dir)
	
	# Find all .tscn files
	var files: Array[String] = []
	_find_tscn_files("res://", files)
	
	for file_path: String in files:
		# Create backup
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if not file:
			push_error("Failed to open file: " + file_path)
			continue
			
		var content: String = file.get_as_text()
		file = null  # Close the file
		
		# Save backup
		var backup_path: String = backup_dir + file_path.get_file().get_basename() + ".backup.tscn"
		var backup_file: FileAccess = FileAccess.open(backup_path, FileAccess.WRITE)
		if not backup_file:
			push_error("Failed to create backup: " + backup_path)
			continue
		var _1: int =  backup_file.store_string(content)
		backup_file = null
		
		# Process the file
		var lines: PackedStringArray = content.split("\n")
		var modified: bool = false
		
		for i: int in lines.size():
			var line: String = lines[i].strip_edges()
			
			# Skip empty lines and comments
			if line.is_empty() or line.begins_with("[") or line.begins_with("#"):
				continue
			
			# Scale position and size properties
			if "position = Vector2(" in line or "size = Vector2(" in line or "rect_min_size = Vector2(" in line:
				var start: int = line.find("(") + 1
				var end: int = line.find(")")
				if start > 0 and end > start:
					var values: PackedStringArray = line.substr(start, end - start).split(",")
					if values.size() == 2:
						var x: float = values[0].to_float() * SCALE_FACTOR
						var y: float = values[1].to_float() * SCALE_FACTOR
						lines[i] = line.substr(0, start) + str(x) + ", " + str(y) + line.substr(end)
						modified = true
		
			# Scale font sizes
			elif "size = " in line and ("font_size" in line or "font_size_override" in line):
				var value: String = line.split("= ")[1].strip_edges()
				if value.is_valid_float():
					var new_size: int = int(value.to_float() * SCALE_FACTOR)
					lines[i] = line.replace(value, str(new_size))
					modified = true
		
		if modified:
			# Save the modified file
			var new_content: String = "\n".join(lines)
			var output_file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
			if output_file:
				var _2: int = output_file.store_string(new_content)
				print("Updated: ", file_path)
			else:
				push_error("Failed to save: " + file_path)
		else:
			print("No changes needed: ", file_path)
		
	print("\nUI upscaling complete! Backups saved to: ", backup_dir)

func _find_tscn_files(path: String, files: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		return
		
	var _1: int = dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			_find_tscn_files(path.path_join(file_name), files)
		elif file_name.ends_with(".tscn"):
			files.append(path.path_join(file_name))
		file_name = dir.get_next()
