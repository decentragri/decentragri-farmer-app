extends Node

# Stake tokens request variables
var StakeTokens: HTTPRequest
var wrStakeTokens: WeakRef
signal stake_tokens_complete(message: Dictionary)

# Get stake info request variables
var GetStakeInfo: HTTPRequest
var wrGetStakeInfo: WeakRef
signal get_stake_info_complete(stake_info: Dictionary)

# Get staker info request variables
var GetStakerInfo: HTTPRequest
var wrGetStakerInfo: WeakRef
signal get_staker_info_complete(staker_info: Dictionary)

# Claim rewards request variables
var ClaimRewards: HTTPRequest
var wrClaimRewards: WeakRef
signal claim_rewards_complete(message: Dictionary)

# Withdraw tokens request variables
var WithdrawTokens: HTTPRequest
var wrWithdrawTokens: WeakRef
signal withdraw_tokens_complete(message: Dictionary)

# Get release timeframe request variables
var GetReleaseTimeFrame: HTTPRequest
var wrGetReleaseTimeFrame: WeakRef
signal get_release_timeframe_complete(timeframe: Dictionary)


func stake_tokens(amount: String) -> void:
	# Prepare HTTP request for staking tokens
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	StakeTokens = prepared_http_req.request
	wrStakeTokens = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to stake tokens")
	
	# Prepare the payload
	var payload: Dictionary = { "amount": amount }
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/tokens"
	
	# Send the POST request with retry capability
	Utils.send_post_request_with_retry(StakeTokens, request_url, payload, _on_stake_tokens_request_completed)


func stake_tokens_without_retry(amount: String) -> void:
	# Fallback function for manual calls without retry
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	StakeTokens = prepared_http_req.request
	wrStakeTokens = prepared_http_req.weakref
	
	# Connect the callback function to handle the completion of the request
	var _connect: int = StakeTokens.request_completed.connect(_on_stake_tokens_request_completed)
	
	# Log the initiation of the request
	Utils.logger.info("Call to stake tokens (no retry)")
	
	# Prepare the payload
	var payload: Dictionary = { "amount": amount }
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/tokens"
	
	# Send the POST request
	Utils.send_post_request(StakeTokens, request_url, payload)


func _on_stake_tokens_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					stake_tokens_complete.emit({ "error": json_body.error })
				else:
					stake_tokens_complete.emit(json_body)
		else:
			stake_tokens_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			stake_tokens_complete.emit({ "error": json_body.error })
		else:
			stake_tokens_complete.emit({ "error": "Unknown server error" })


func get_stake_info() -> void:
	# Prepare HTTP request for getting stake info
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetStakeInfo = prepared_http_req.request
	wrGetStakeInfo = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to get stake info")
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/info"
	
	# Send the GET request with retry capability
	Utils.send_get_request_with_retry(GetStakeInfo, request_url, _on_get_stake_info_request_completed)


func _on_get_stake_info_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_stake_info_complete.emit({ "error": json_body.error })
			else:
				get_stake_info_complete.emit(json_body)
		else:
			get_stake_info_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			get_stake_info_complete.emit({ "error": json_body.error })
		else:
			get_stake_info_complete.emit({ "error": "Unknown server error" })


func get_staker_info() -> void:
	# Prepare HTTP request for getting staker info
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetStakerInfo = prepared_http_req.request
	wrGetStakerInfo = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to get staker info")
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/staker"
	
	# Send the GET request with retry
	Utils.send_get_request_with_retry(GetStakerInfo, request_url, _on_get_staker_info_request_completed)


func _on_get_staker_info_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_staker_info_complete.emit({ "error": json_body.error })
			else:
				get_staker_info_complete.emit(json_body)
		else:
			get_staker_info_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			get_staker_info_complete.emit({ "error": json_body.error })
		else:
			get_staker_info_complete.emit({ "error": "Unknown server error" })


func claim_rewards() -> void:
	# Prepare HTTP request for claiming rewards
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	ClaimRewards = prepared_http_req.request
	wrClaimRewards = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to claim rewards")
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/claim"
	
	# Send the POST request with empty payload and retry
	Utils.send_post_request_with_retry(ClaimRewards, request_url, {}, _on_claim_rewards_request_completed)


func _on_claim_rewards_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					claim_rewards_complete.emit({ "error": json_body.error })
				else:
					claim_rewards_complete.emit(json_body)
		else:
			claim_rewards_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			claim_rewards_complete.emit({ "error": json_body.error })
		else:
			claim_rewards_complete.emit({ "error": "Unknown server error" })


func withdraw_tokens(amount: String) -> void:
	# Prepare HTTP request for withdrawing tokens
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	WithdrawTokens = prepared_http_req.request
	wrWithdrawTokens = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to withdraw tokens")
	
	# Prepare the payload
	var payload: Dictionary = { "amount": amount }
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/withdraw"
	
	# Send the POST request with retry
	Utils.send_post_request_with_retry(WithdrawTokens, request_url, payload, _on_withdraw_tokens_request_completed)


func _on_withdraw_tokens_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					withdraw_tokens_complete.emit({ "error": json_body.error })
				else:
					withdraw_tokens_complete.emit(json_body)
		else:
			withdraw_tokens_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			withdraw_tokens_complete.emit({ "error": json_body.error })
		else:
			withdraw_tokens_complete.emit({ "error": "Unknown server error" })


func get_release_timeframe() -> void:
	# Prepare HTTP request for getting release timeframe
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetReleaseTimeFrame = prepared_http_req.request
	wrGetReleaseTimeFrame = prepared_http_req.weakref
	
	# Log the initiation of the request
	Utils.logger.info("Call to get release timeframe")
	
	# Construct the request URL
	var request_url: String = Utils.host + "/api/stake/timeframe"
	
	# Send the GET request with retry
	Utils.send_get_request_with_retry(GetReleaseTimeFrame, request_url, _on_get_release_timeframe_request_completed)


func _on_get_release_timeframe_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_release_timeframe_complete.emit({ "error": json_body.error })
			else:
				get_release_timeframe_complete.emit(json_body)
		else:
			get_release_timeframe_complete.emit({ "error": "Unknown server error" })
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null and json_body.has("error"):
			get_release_timeframe_complete.emit({ "error": json_body.error })
		else:
			get_release_timeframe_complete.emit({ "error": "Unknown server error" })
