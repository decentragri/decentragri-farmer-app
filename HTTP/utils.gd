extends Node

const logger: Script = preload("res://HTTP/logger.gd")

const host_ip: String = "api.decentragri.com"
var host: String = "https://" + host_ip

# Retry configuration
const RETRY_CONFIG: Dictionary = {
	"max_retries": 3,
	"base_delay": 1.0,  # Base delay in seconds
	"max_delay": 30.0,  # Maximum delay in seconds
	"backoff_multiplier": 2.0,  # Exponential backoff multiplier
	"retryable_codes": [0, 408, 429, 500, 502, 503, 504]  # HTTP codes that should trigger retry
}

const auth_config: Dictionary[String, int] = {
	"session_duration_seconds": 0,
}

# Prepares an HTTP request and returns a dictionary containing the request object and its WeakRef.
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

# Check if a response code should trigger a retry
static func should_retry(response_code: int) -> bool:
	return response_code in RETRY_CONFIG.retryable_codes

# Calculate retry delay with exponential backoff
static func get_retry_delay(attempt: int) -> float:
	var delay: float = RETRY_CONFIG.base_delay * pow(RETRY_CONFIG.backoff_multiplier, attempt - 1)
	return min(delay, RETRY_CONFIG.max_delay)

# Retry wrapper for HTTP requests
func send_request_with_retry(
	request_func: Callable, 
	args: Array
) -> void:
	# Execute the request function with provided arguments
	request_func.callv(args)

# Enhanced GET request with retry capability
func send_get_request_with_retry(
	http_node: HTTPRequest, 
	request_url: String, 
	callback: Callable,
	retry_count: int = 0
) -> void:
	
	# Disconnect any existing connections to avoid duplicates
	if http_node.request_completed.is_connected(callback):
		http_node.request_completed.disconnect(callback)
	
	# Create a wrapper callback that handles retries
	var retry_callback: Callable = func(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
		if should_retry(response_code) and retry_count < RETRY_CONFIG.max_retries:
			logger.info("Request failed with code %d. Retrying... (attempt %d/%d)" % [response_code, retry_count + 1, RETRY_CONFIG.max_retries])
			
			# Wait before retrying with exponential backoff
			var delay: float = get_retry_delay(retry_count + 1)
			await get_tree().create_timer(delay).timeout
			
			# Retry the request
			send_get_request_with_retry(http_node, request_url, callback, retry_count + 1)
		else:
			# Either success or max retries reached - call original callback
			callback.call(_result, response_code, headers, body)
	
	# Connect the retry wrapper callback
	var _connect: int = http_node.request_completed.connect(retry_callback, CONNECT_ONE_SHOT)
	
	# Send the actual request
	send_get_request(http_node, request_url)

# Enhanced POST request with retry capability  
func send_post_request_with_retry(
	http_node: HTTPRequest, 
	request_url: String, 
	payload: Variant,
	callback: Callable,
	retry_count: int = 0
) -> void:
	
	# Disconnect any existing connections to avoid duplicates
	if http_node.request_completed.is_connected(callback):
		http_node.request_completed.disconnect(callback)
	
	# Create a wrapper callback that handles retries
	var retry_callback: Callable = func(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
		if should_retry(response_code) and retry_count < RETRY_CONFIG.max_retries:
			logger.info("Request failed with code %d. Retrying... (attempt %d/%d)" % [response_code, retry_count + 1, RETRY_CONFIG.max_retries])
			
			# Wait before retrying with exponential backoff
			var delay: float = get_retry_delay(retry_count + 1)
			await get_tree().create_timer(delay).timeout
			
			# Retry the request
			send_post_request_with_retry(http_node, request_url, payload, callback, retry_count + 1)
		else:
			# Either success or max retries reached - call original callback
			callback.call(_result, response_code, headers, body)
	
	# Connect the retry wrapper callback
	var _connect: int = http_node.request_completed.connect(retry_callback, CONNECT_ONE_SHOT)
	
	# Send the actual request
	send_post_request(http_node, request_url, payload)

# NEW: Enhanced PATCH request with retry capability  
func send_patch_request_with_retry(
	http_node: HTTPRequest, 
	request_url: String, 
	payload: Variant,
	callback: Callable,
	retry_count: int = 0
) -> void:
	
	# Disconnect any existing connections to avoid duplicates
	if http_node.request_completed.is_connected(callback):
		http_node.request_completed.disconnect(callback)
	
	# Create a wrapper callback that handles retries
	var retry_callback: Callable = func(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
		if should_retry(response_code) and retry_count < RETRY_CONFIG.max_retries:
			logger.info("PATCH request failed with code %d. Retrying... (attempt %d/%d)" % [response_code, retry_count + 1, RETRY_CONFIG.max_retries])
			
			# Wait before retrying with exponential backoff
			var delay: float = get_retry_delay(retry_count + 1)
			await get_tree().create_timer(delay).timeout
			
			# Retry the request
			send_patch_request_with_retry(http_node, request_url, payload, callback, retry_count + 1)
		else:
			# Either success or max retries reached - call original callback
			callback.call(_result, response_code, headers, body)
	
	# Connect the retry wrapper callback
	var _connect: int = http_node.request_completed.connect(retry_callback, CONNECT_ONE_SHOT)
	
	# Send the actual request
	send_patch_request(http_node, request_url, payload)

# Enhanced login request with retry capability
func send_login_request_with_retry(
	http_node: HTTPRequest, 
	request_url: String, 
	payload: Dictionary,
	callback: Callable,
	retry_count: int = 0
) -> void:
	
	# Disconnect any existing connections to avoid duplicates
	if http_node.request_completed.is_connected(callback):
		http_node.request_completed.disconnect(callback)
	
	# Create a wrapper callback that handles retries
	var retry_callback: Callable = func(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
		if should_retry(response_code) and retry_count < RETRY_CONFIG.max_retries:
			logger.info("Login request failed with code %d. Retrying... (attempt %d/%d)" % [response_code, retry_count + 1, RETRY_CONFIG.max_retries])
			
			# Wait before retrying with exponential backoff
			var delay: float = get_retry_delay(retry_count + 1)
			await get_tree().create_timer(delay).timeout
			
			# Retry the request
			send_login_request_with_retry(http_node, request_url, payload, callback, retry_count + 1)
		else:
			# Either success or max retries reached - call original callback
			callback.call(_result, response_code, headers, body)
	
	# Connect the retry wrapper callback
	var _connect: int = http_node.request_completed.connect(retry_callback, CONNECT_ONE_SHOT)
	
	# Send the actual request
	send_login_request(http_node, request_url, payload)

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

# NEW: PATCH request method (following your existing pattern)
func send_patch_request(http_node: HTTPRequest, request_url: String, payload: Variant) -> void:
	var headers: Array[String] = [
		"content-Type: application/json",
	]
	headers = add_jwt_token_headers(headers)
	if !http_node.is_inside_tree():
		await get_tree().create_timer(1).timeout
		
	var query: String = JSON.stringify(payload)
	logger.debug("Method: PATCH")
	logger.debug("request_url: " + str(request_url))
	logger.debug("headers: " + str(headers))
	logger.debug("query: " + str(query))
	var _request_patch_send: Error = http_node.request(request_url, headers, HTTPClient.METHOD_PATCH, query)
	
	
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

func get_scaled_png_bytes(image: Image, max_size: float = 512) -> PackedByteArray:
	if image == null:
		return []
	var w: float = image.get_width()
	var h: float = image.get_height()

	if w > max_size or h > max_size:
		var maxim: float = max(w, h)
		var scale_down: float = float(max_size) / float(maxim)
		@warning_ignore("narrowing_conversion")
		image.resize(w * scale_down, h * scale_down, Image.INTERPOLATE_LANCZOS)
		
	return image.save_png_to_buffer()

func generate_uuid_v4() -> String:
	var b: Array = uuid_bin()
	var low: String = "%02x%02x%02x%02x" % [b[0], b[1], b[2], b[3]]
	var mid: String = "%02x%02x" % [b[4], b[5]]
	var hi: String = "%02x%02x" % [b[6], b[7]]
	var clock: String = "%02x%02x" % [b[8], b[9]]
	var node: String = "%02x%02x%02x%02x%02x%02x" % [b[10], b[11], b[12], b[13], b[14], b[15]]
	return "%s-%s-%s-%s-%s" % [low, mid, hi, clock, node]

static func uuid_bin() -> Array:
	var b: Array = random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return b

static func random_bytes(n: int) -> Array:
	var r: Array = []
	for index: int in range(0, n):
		r.append(get_random_int(256))
	return r

static func get_random_int(max_value: int) -> int:
	randomize()
	return randi() % max_value
