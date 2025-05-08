extends Node


static func get_log_level() -> int:
	var log_level: int = 2 
	return log_level
	
	
static func error(text: String) -> void:
	printerr(str(text))
	push_error(str(text))


static func info(text: String) -> void:
	if get_log_level() > 0:
		print(str(text))
	
	
static func debug(text: String) -> void:
	if get_log_level() > 1:
		print(str(text))
		
		
static func log_time(log_text: String, log_level: String ='INFO') -> void:
	var timestamp: int = int(get_timestamp())
	if log_level == 'ERROR':
		error(log_text + ": " + str(timestamp))
	elif log_level == 'INFO':
		info(log_text + ": " + str(timestamp))
	else:
		debug(log_text + ": " + str(timestamp))


static func get_timestamp() -> float:
	var unix_time: float = Time.get_unix_time_from_system()
	@warning_ignore("narrowing_conversion")
	var unix_time_int: int = unix_time
	var timestamp: float = round((unix_time - unix_time_int) * 1000.0)
	return timestamp

static func check_http_response(response_code: int, headers: Array, _body: PackedByteArray) -> bool:
	debug("response code: " + str(response_code))
	debug("response headers: " + str(headers))
	var check_ok:bool = true
	if response_code == 0:
		no_connection_error()
		check_ok = false
	elif response_code == 403:
		forbidden_error()
		check_ok = false
	elif response_code == 401:
		forbidden_error()
		check_ok = false
	elif response_code == 422:
		forbidden_error()
		check_ok = false
	elif response_code == 404:
		forbidden_error()
		check_ok = false
	elif response_code == 500:
		forbidden_error()
		check_ok = false
	return check_ok
	
	
static func no_connection_error() -> void:
	error("Beats couldn't connect to the server. There are several reasons why this might happen. See https://www.gmetarave.com/troubleshooting for more details. If the problem persists you can reach out to us: https://www.gmetarave.com/contact")

static func forbidden_error() -> void:
	error("You are not authorized to call - check your device or account")

static func validation_error() -> void:
	error("Your credentials entered or used are invalid")

static func obfuscate_string(string: String) -> String:
	return string.replace(".", "*")
