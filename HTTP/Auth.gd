extends Node


const utils_static: Script = preload("res://HTTP/utils.gd")

var ValidateSession: HTTPRequest 
var wrValidateSession: WeakRef
signal session_check_complete(session: Dictionary)


var Login: HTTPRequest
var wrLogin: WeakRef
signal login_complete
signal logout_complete

var Register: HTTPRequest
var wrRegister: WeakRef
signal registration_complete

var RenewToken: HTTPRequest
var wrRenewToken: WeakRef
signal token_renew_complete

var SaveFcmToken: HTTPRequest
var wrSaveFcmToken: WeakRef
signal save_fcm_token_complete


var login_type: String
var last_login_type: String

var access_token: String
var refresh_token: String
var offline_mode: bool = false

var login_timeout: int = 0
var login_timer: Timer
var logged_in_user: String
var complete_session_check_wait_timer: Timer


func auto_login_user() -> void:
	# Load saved session data
	var session_data: Dictionary = await load_session()
	Utils.logger.debug("Session data " + str(session_data))
	
	# Check if session data is available for autologin
	if session_data:
		Utils.logger.debug("Found saved session data, attempting autologin...")
		# Extract access and refresh token from the saved session data
		if session_data.has("access_token") and session_data.has("refresh_token") and session_data.has("login_type"):
			access_token = session_data.access_token
			refresh_token = session_data.refresh_token
			last_login_type = session_data.login_type
			logged_in_user = str(session_data.get("username", ""))
			
			# Try to validate session online, fallback to offline if network/server fails
			var _tried_online: bool = false
			if last_login_type == 'decentragri' or last_login_type == 'passkey':
				_tried_online = true
				offline_mode = false
				# Start validation and wait for completion or timeout
				validate_session()
				
				# Wait for online validation or timeout
				var wait_time: float = 3.0
				var timer: SceneTreeTimer = get_tree().create_timer(wait_time)
				await timer.timeout
				
				# If we reach here, either validation completed or timed out
				# Check if we're still waiting for validation (no success yet)
				if not offline_mode:
					Utils.logger.info("Online validation timed out, falling back to offline login mode.")
					offline_mode = true
					complete_session_check({"offline": true, "username": logged_in_user})
			else:
				# Unknown login type, go offline
				offline_mode = true
				complete_session_check({"offline": true, "username": logged_in_user})
		else:
			Utils.logger.debug("No saved  session data, so no autologin will be performed")
			# Set up a timer to delay the emission of the signal for a short duration
			setup_complete_session_check_wait_timer()
			complete_session_check_wait_timer.start()
	else:
		# If no saved session data is available, log the absence and initiate a delayed session check
		Utils.logger.debug("No saved session data, so no autologin will be performed")
		
		# Set up a timer to delay the emission of the signal for a short duration
		setup_complete_session_check_wait_timer()
		complete_session_check_wait_timer.start()
	
	
func load_session(max_age_seconds: int = 60 * 60 * 24 * 30) -> Dictionary:
	var session_data: Variant

	if OS.get_name() == "Android":
		Utils.logger.debug("Loading session from Android plugin")
		SessionTokens.retrieve_jwt_tokens()
		session_data = await SessionTokens.jwt_retrieve_completed
	else:
		Utils.logger.debug("Loading session from local file storage")
		const path: String = "user://decentrasession.save"
		session_data = utils_static.get_data(path)

	if session_data == null or session_data.is_empty():
		var source: String
		if OS.get_name() == "Android":
			source = "Android plugin"
		else:
			source = "local storage"
		Utils.logger.debug("No session data found from " + source)
		return {}

	# Check session age (optional, default 30 days)
	if session_data.has("timestamp"):
		var now: float = Time.get_unix_time_from_system()
		var age: float = now - float(str(session_data.timestamp))
		if age > max_age_seconds:
			Utils.logger.info("Session expired (age: %d seconds)" % age)
			return {}

	Utils.logger.info("Loaded session data: " + str(session_data))
	return session_data


func validate_session() -> void:
	# Prepare the HTTP request for session validation
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	ValidateSession = prepared_http_req.request
	wrValidateSession = prepared_http_req.weakref
	
	# Log the initiation of  session validation
	Utils.logger.info("Calling  to validate an existing  session")
	# Create the payload with lookup and access tokens
	var payload: Dictionary = {}
	# Log the payload details
	Utils.logger.debug("Validate session payload: " + str(payload))
	# Construct the request URL
	var request_url: String = Utils.host + "/api/validate-session/decentra"
	# Send the POST request for session validation with retry
	Utils.send_login_request_with_retry(ValidateSession, request_url, payload, _on_ValidateSession_request_completed)
	# Return the current script instance
	
	
func complete_session_check(session_check: Dictionary = {}) -> void:
	# Log a debug message indicating the completion of the session check
	Utils.logger.debug("completing session check")
	session_check_complete.emit(session_check)
	
	
func _on_ValidateSession_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the status of the HTTP response
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Handle the result based on the status check
	if status_check:
		# Parse the JSON body of the response
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			offline_mode = false
			complete_session_check({ })
			return
			
		var result_body: Dictionary = json_body
		# Build a result dictionary from the JSON body

		if json_body.has("error"):
			Utils.logger.error("validate session failure: " + str(json_body.error))
			offline_mode = false
		elif json_body.has("success"):
			# Log success and set the  as logged in
			Utils.logger.info("validate session success.")
			offline_mode = false
			
			var username: String = json_body.username
			set_user_logged_in(username)
			
		if "accessToken" in json_body.keys():
			Utils.logger.debug("Remember me access: " + str(json_body.accessToken))
			# Save the session and set the  as logged in
			access_token = json_body.accessToken
			refresh_token = json_body.refreshToken
			login_type = json_body.loginType
			
			login_complete.emit(result_body)
			save_session(access_token, refresh_token, login_type, logged_in_user)

		# Trigger the completion of the session check with the result
		result_body["offline"] = false
		complete_session_check(result_body)
		renew_access_token_timer()
	else:
		# Trigger the completion of the session check with an empty result in case of failure
		offline_mode = false
		complete_session_check({ })
	
	
func save_fcm_token(token: String) -> void:
	# Prepare the HTTP request for session validation
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SaveFcmToken = prepared_http_req.request
	wrSaveFcmToken = prepared_http_req.weakref
	Utils.logger.info("Calling to save FCM token")
	
	var payload: Dictionary = { "token": token }
	var request_url: String = Utils.host + "/api/save/fcm-token/android"
	Utils.send_post_request_with_retry(SaveFcmToken, request_url, payload, _on_SaveFcmToken_request_completed)
	
	
func _on_SaveFcmToken_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					save_fcm_token_complete.emit({ "error": json_body.error })
				else:
					save_fcm_token_complete.emit(json_body)
		else:
			save_fcm_token_complete.emit({ "error": "Unknown server error" })
	else:
		save_fcm_token_complete.emit({ "error": "Unknown server error" })




#endregion


func login(username: String, password: String) -> void:
	# Store the username temporarily for reference in the callback function
	# Prepare the HTTP request for  login
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	Login = prepared_http_req.request
	wrLogin = prepared_http_req.weakref
	
	# Log information about the login attempt
	Utils.logger.info("Calling to log in user")
	
	# Prepare the payload for the login request
	var payload: Dictionary[String, String] = { "username": username, "password": password }
	
	# Obfuscate the password before logging and sending the request
	var payload_for_logging: Dictionary[String, String] = payload
	var obfuscated_password: String = Utils.logger.obfuscate_string(payload["password"])

	payload_for_logging["password"] = obfuscated_password
	Utils.logger.debug("login payload: " + str(payload_for_logging))
	
	# Define the request URL for login
	var request_url: String = Utils.host + "/api/login/decentra"
	Utils.send_login_request_with_retry(Login, request_url, payload, _on_Login_request_completed)
	
	
func _on_Login_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var json_string: String = body.get_string_from_utf8()
	var json_body: Variant = JSON.parse_string(json_string)

	if json_body == null:
		login_complete.emit({"error": "Unknown server error"})
		return

	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)

	if status_check:
		if json_body.has("accessToken"):
			Utils.logger.debug("Remember me access: " + str(json_body.accessToken))
		if json_body.has("refreshToken"):
			Utils.logger.debug("Remember me refresh: " + str(json_body.refreshToken))

			access_token = json_body.accessToken
			refresh_token = json_body.refreshToken
			login_type = json_body.loginType

			var username: String = json_body.username
			save_session(access_token, refresh_token, login_type, username)
			set_user_logged_in(username)

			renew_access_token_timer()
			login_complete.emit(json_body)
		elif json_body.has("error"):
			Utils.logger.error("Login failure: " + str(json_body.error))
			login_complete.emit(json_body)
		else:
			login_complete.emit({"error": "Unknown server error"})
	else:
		if json_body.has("name") and json_body.name == "Error":
			login_complete.emit({"error": json_body.message})
		elif json_body.has("error"):
			login_complete.emit({"error": json_body.error})
		else:
			login_complete.emit({"error": "Unknown server error"})
	
	
func register(username: String, password: String ) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	Register = prepared_http_req.request
	wrRegister = prepared_http_req.weakref
	Utils.logger.info("Calling to register")
	
	var payload: Dictionary[String, String] = { 
		"username": username, 
		"password": password,
		"deviceId": OS.get_model_name()
	}
	
	var request_url: String = Utils.host + "/api/register/decentra"
	Utils.send_post_request_with_retry(Register, request_url, payload, _on_Register_request_completed)


# Callback function triggered upon completion of the registration request
func _on_Register_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body.has("error"):
			registration_complete.emit({ "error": json_body.error })
		elif json_body.has("walletAddress"):
			registration_complete.emit(json_body)
			refresh_token = json_body.refreshToken
			access_token = json_body.accessToken
			login_type = json_body.loginType
			var username: String = json_body.username
			set_user_logged_in(username)
			save_session(access_token, refresh_token, login_type, username)
			renew_access_token_timer()
			Utils.logger.info("Register success")
		else:
			registration_complete.emit({ "error": "Unknown error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null or "":
			if "error" in json_body:
				registration_complete.emit({ "error": json_body.error })
			else:
				Utils.logger.error("registration failure: " + str(json_body))
				registration_complete.emit({ "error": str(json_body) })
		else:
			Utils.logger.error("Unknown server Error")
			
	
	
func setup_complete_session_check_wait_timer() -> void:
	# Create a new one-shot timer
	complete_session_check_wait_timer = Timer.new()
	
	# Configure the timer to be a one-shot timer with a small wait time (0.01 seconds)
	complete_session_check_wait_timer.set_one_shot(true)
	complete_session_check_wait_timer.set_wait_time(0.01)
	
	# Connect the timeout signal of the timer to the 'complete_session_check' function
	var _session_timer_signal: int = complete_session_check_wait_timer.timeout.connect(complete_session_check)
	
	# Add the timer as a child of the current node
	add_child(complete_session_check_wait_timer)


func set_user_logged_in(user_name: String) -> void:
	# Set the global variable for the logged-in user
	logged_in_user = user_name
	
	# Log information about being logged in
	Utils.logger.info("logged in as " + str(user_name))
	
	# Check for session duration configuration in the authentication settings
	if Utils.auth_config.has("session_duration_seconds") and typeof(Utils.auth_config.session_duration_seconds) == 2:
		login_timeout = Utils.auth_config.session_duration_seconds
	else:
		login_timeout = 0
	
	# Log information about the login timeout configuration
	Utils.logger.info("login timeout: " + str(login_timeout))
	
	# If a login timeout is specified, set up the login timer
	if login_timeout != 0:
		setup_login_timer()
		
		
func save_session(token_access: String, token_refresh: String, type_login: String, username: String = "", extra: Dictionary = {}) -> void:
	# Log debug information about the session being saved
	Utils.logger.debug("Saving session, access: " + str(token_access) + ", refresh: " + str(token_refresh))
	var session_data: Dictionary = {
		"access_token": token_access,
		"refresh_token": token_refresh,
		"login_type": type_login,
		"username": username,
		"timestamp": Time.get_unix_time_from_system()
	}
	for k: String in extra.keys():
		session_data[k] = extra[k]
	# Check if the OS is Android
	if OS.get_name() == "Android":
		SessionTokens.store_jwt_tokens(session_data)
	else:
		# Save the session data dictionary to a local file with the specified path
		utils_static.save_data("user://decentrasession.save", session_data, "Saving  session: ")


func setup_login_timer() -> void:
	login_timer = Timer.new()
	login_timer.set_one_shot(true)
	login_timer.set_wait_time(login_timeout)
	var _timer_signal: int = login_timer.timeout.connect(on_login_timeout_complete)
	add_child(login_timer)
	
	
func on_login_timeout_complete() -> void:
	logout()
	
	
func logout() -> void:
	# Clear the logged-in information
	# Remove stored session if any and log the deletion success
	var delete_success: bool = remove_stored_session()
	print("delete_success: " + str(delete_success))
	
	# Emit signal indicating completion of  logout
	logout_complete.emit()
	get_tree().quit()
	
func remove_stored_session() -> bool:
	if OS.get_name() == "Android":
		SessionTokens.clear_jwt_tokens()
	else:
		var path: String = "user://decentrasession.save"
		# Attempt to delete the file and log the result
		var delete_success: bool = utils_static.remove_data(path, "Removing session if any: " )
		return delete_success
	return true
	

func renew_access_token_timer() -> void:
	# Create a timer that fires every 4 minutes (240 seconds)
	var timer: SceneTreeTimer = get_tree().create_timer(200.0)
	var _renew: int = timer.timeout.connect(renew_access_token_timer)
	var _connect: int = timer.timeout.connect(request_new_access_token)
	
	
func request_new_access_token() -> void:
	# This function will be called every 4 minutes
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	RenewToken = prepared_http_req.request
	wrRenewToken = prepared_http_req.weakref
	# Add your JWT decoding logic here
		# Log the initiation of  session validation
	Utils.logger.info("Calling to validate an existing session")
	# Create the payload with lookup and access tokens
	var payload: Dictionary = {}
	# Log the payload details
	Utils.logger.debug("Validate session payload: " + str(payload))
	var request_url: String = Utils.host + "/api/renew/access/decentra"
	# Send the POST request for session validation with retry
	Utils.send_login_request_with_retry(RenewToken, request_url, payload, _on_RequestNewAccessToken_completed)
	# Return the current script instance


func _on_RequestNewAccessToken_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the status of the HTTP response
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	# Handle the result based on the status check
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body == null:
			token_renew_complete.emit({})
			return
		if json_body.has("error"):
			Utils.logger.error("renew token failure: " + str(json_body.error))
			return
		if "refreshToken" in json_body.keys():
			Utils.logger.debug("Remember me access: " + str(json_body.accessToken))
			# Save the session and set the as logged in
			refresh_token = json_body.refreshToken
			access_token = json_body.accessToken
			save_session(access_token, refresh_token, login_type, logged_in_user)
			token_renew_complete.emit(json_body)
	else:
		# Trigger the completion of the session check with an empty result in case of failure
		token_renew_complete.emit({})
