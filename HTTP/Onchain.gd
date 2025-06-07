extends Node

var GetETHRSWETHRate: HTTPRequest
var wrGetETHRSWETHRate: WeakRef
signal get_eth_to_rsweth_rate_completed(rate: Dictionary)

var GetRewardRate: HTTPRequest
var wrGetRewardRate: WeakRef
signal get_reward_rate_completed(rate: int)

var StakeETH: HTTPRequest
var wrStakeETH: WeakRef
signal stake_eth_completed(message: Dictionary)

var TransferToken: HTTPRequest
var wrTransferToken: WeakRef
signal transfer_token_completed(message: Dictionary)


func get_eth_to_rsweth_rate() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetETHRSWETHRate = prepared_http_req.request
	wrGetETHRSWETHRate = prepared_http_req.weakref

	var _connect: int = GetETHRSWETHRate.request_completed.connect(_on_GetETHRSWETHRate_request_completed)
	Utils.logger.info("Calling to exchange rate soil meter data")
	var request_url: String = Utils.host + "/api/onchain/eth-rsweth/rate"

	Utils.send_get_request(GetETHRSWETHRate, request_url)


func _on_GetETHRSWETHRate_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_eth_to_rsweth_rate_completed.emit({"error": json_body.error})
			else:
				get_eth_to_rsweth_rate_completed.emit(json_body)
		else:
			get_eth_to_rsweth_rate_completed.emit({"error": "Unknown server error"})
	else:
		get_eth_to_rsweth_rate_completed.emit({"error": "Unknown server error"})
		
		
func get_reward_rate() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetRewardRate = prepared_http_req.request
	wrGetRewardRate = prepared_http_req.weakref

	var _connect: int = GetRewardRate.request_completed.connect(_on_GetRewardRate_request_completed)
	Utils.logger.info("Calling to exchange rate soil meter data")
	var request_url: String = Utils.host + "/api/onchain/reward-percentage/price"

	Utils.send_get_request(GetRewardRate, request_url)


func _on_GetRewardRate_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_reward_rate_completed.emit({"error": json_body.error})
			else:
				get_reward_rate_completed.emit(json_body)
		else:
			get_reward_rate_completed.emit({"error": "Unknown server error"})
	else:
		get_reward_rate_completed.emit({"error": "Unknown server error"})
		
		
func stake_eth(eth_amount: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	StakeETH = prepared_http_req.request
	wrStakeETH = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = StakeETH.request_completed.connect(_on_StakeETH_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to stake ETH")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/onchain/stake/eth"
	var payload: Dictionary[String, String] = { "ethAmount": eth_amount }

	# Send the GET request using the prepared URL.
	Utils.send_post_request(StakeETH, request_url, payload)
	
	
func _on_StakeETH_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					stake_eth_completed.emit({ "error": json_body.error })
				else:
					print("shit: ", json_body)
					stake_eth_completed.emit(json_body)
		else:
			stake_eth_completed.emit({ "error": "Unknown server error" })
	else:
		stake_eth_completed.emit({ "error": "Unknown server error" })


func transfer_token(token_transfer_data: Dictionary[String, String]) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	TransferToken = prepared_http_req.request
	wrTransferToken = prepared_http_req.weakref

	# Connect the callback function to handle the completion of the leaderboard data request.
	var _connect: int = TransferToken.request_completed.connect(_on_TransferToken_request_completed)

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to stake ETH")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/onchain/token/transfer"
	var payload: Dictionary[String, String] = token_transfer_data

	# Send the GET request using the prepared URL.
	Utils.send_post_request(StakeETH, request_url, payload)
	
	
func _on_TransferToken_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					transfer_token_completed.emit({ "error": json_body.error })
				else:
					transfer_token_completed.emit(json_body)
		else:
			transfer_token_completed.emit({ "error": "Unknown server error" })
	else:
		transfer_token_completed.emit({ "error": "Unknown server error" })
