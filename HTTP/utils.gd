extends Node

const logger: Script = preload("res://HTTP/logger.gd")

const host_ip: String = "api.decentragri.com"
var host: String = "https://" + host_ip




const auth_config: Dictionary[String, int] = {
	"session_duration_seconds": 0,
}



# Prepares an HTTP request and returns a dictiothe unary containing the request object and its WeakRef.
func prepare_http_request() -> Dictionary[String, Variant]:
	var request: HTTPRequest = HTTPRequest.new()
	var weak_ref: WeakRef = weakref(request)
	if OS.get_name() != "Web":
		request.set_use_threads(true)
	request.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().call_deferred("add_child", request)
	var return_dict: Dictionary[String, Variant] = {
		"request": request, 
		"weakref": weak_ref
	}
	return return_dict
	
	
func send_get_request(http_node: HTTPRequest, request_url: String) -> void:
	var headers: Array[String] = [
		"content-Type: application/json",
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(1).timeout

	logger.debug("Method: GET")
	logger.debug("request_url: " + str(request_url))
	logger.debug("headers: " + str(headers))
	var _get_request_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_GET)
	
	
func add_jwt_token_headers(headers: Array[String] = []) -> Array:
	if Auth.access_token != null:
		headers.append("Authorization: Bearer " + Auth.access_token)
	return headers


func send_post_request(http_node: HTTPRequest, request_url: String, payload: Variant) -> void:
	var headers: Array[String] = [
		"content-Type: application/json",
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(1).timeout
		
	var query: String = JSON.stringify(payload)
	logger.debug("Method: POST")
	logger.debug("request_url: " + str(request_url))
	logger.debug("headers: " + str(headers))
	logger.debug("query: " + str(query))
	var _request_post_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)


func add_jwt_refresh_token_headers(headers: Array[String] = []) -> Array:
	if Auth.refresh_token != null:
		headers.append("Authorization: Bearer " + Auth.refresh_token)
	return headers


func send_login_request(http_node: HTTPRequest, request_url: String, payload: Dictionary) -> void:
	var headers: Array[String] = [
		"content-Type: application/json",
	]
	headers = add_jwt_refresh_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(1).timeout
		
	var query: String = JSON.stringify(payload)
	logger.debug("Method: POST")
	logger.debug("request_url: " + str(request_url))
	logger.debug("headers: " + str(headers))
	logger.debug("query: " + str(query))
	var _request_post_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_POST, query)


static func save_data(path: String, data: Dictionary, debug_message: String='Saving data to file in local storage: ') -> bool:
	var save_success:bool = false
	var file:FileAccess = FileAccess.open(path, FileAccess.WRITE)
	var _t: bool = file.store_string(str(data))
	save_success = true

	logger.debug(debug_message + str(data))
	return save_success


static func remove_data(path: String, debug_message: String='Removing data from file in local storage: ') -> bool:
	var delete_success: bool = false
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		var data: Dictionary = { "deleted": "delete" }
		var _t: bool = file.store_var(data)
		delete_success = true
	logger.debug(debug_message)
	return delete_success


static func does_file_exist(path: String) -> bool:
	return FileAccess.file_exists(path)


static func get_data(path: String) -> Dictionary:
	var content: Dictionary = {}
	if FileAccess.file_exists(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var text_content: String = file.get_as_text()
		if JSON.parse_string(text_content) != null:
			var data: Variant = JSON.parse_string(text_content)
			if typeof(data) == TYPE_DICTIONARY:
				content = data
			else:
				logger.debug("Invalid data in local storage")
	else:
		logger.debug("Could not find any data at: " + str(path))
	return content
	
	
func format_address(address: String) -> String:
	var first_four: String = address.left(12)
	var last_four: String = address.right(4)
	return first_four + "..." + last_four
	
	
func format_balance(value: String) -> String:
	var parts: Array = value.split(".")
	var wholePart: String = parts[0]
	
	# Add commas for every three digits in the whole part.
	var formattedWholePart: String = ""
	var digitCount: int = 0
	for i: int in range(wholePart.length() - 1, -1, -1):
		formattedWholePart = wholePart[i] + formattedWholePart
		digitCount += 1
		if digitCount == 3 and i != 0:
			formattedWholePart = "," + formattedWholePart
			digitCount = 0
	return formattedWholePart
