extends Node



var GetETHSWETHPrice: HTTPRequest
var wrGetETHSWETHPrice: WeakRef
signal get_eth_sweth_price_complete(message: Dictionary)

var GetLastTransactions: HTTPRequest
var wrGetLastTransactions: WeakRef
signal get_last_transactions_complete(message: Dictionary)


func get_eth_sweth_price() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetETHSWETHPrice = prepared_http_req.request
	wrGetETHSWETHPrice = prepared_http_req.weakref

	Utils.logger.info("Calling to get prices")
	var request_url: String = Utils.host + "/api/insight/eth/price"

	Utils.send_get_request_with_retry(GetETHSWETHPrice, request_url, _on_GetPrice_request_completed)
	
	
func _on_GetPrice_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_eth_sweth_price_complete.emit({"error": json_body.error})
			else:
				get_eth_sweth_price_complete.emit(json_body)
		else:
			get_eth_sweth_price_complete.emit({"error": "Unknown server error"})
	else:
		get_eth_sweth_price_complete.emit({"error": "Unknown server error"})


func get_last_transaction(wallet_address: String, chain_id: String) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetLastTransactions = prepared_http_req.request
	wrGetLastTransactions = prepared_http_req.weakref

	Utils.logger.info("Calling to get last transactions")
	var request_url: String = Utils.host + "/api/insight/transactions/" + wallet_address + "/" + chain_id 

	Utils.send_get_request_with_retry(GetLastTransactions, request_url, _on_GetLastTransaction_request_completed)
	
	
func _on_GetLastTransaction_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_last_transactions_complete.emit({"error": json_body.error})
			else:
				get_last_transactions_complete.emit(json_body)
		else:
			get_last_transactions_complete.emit({"error": "Unknown server error"})
	else:
		get_last_transactions_complete.emit({"error": "Unknown server error"})
