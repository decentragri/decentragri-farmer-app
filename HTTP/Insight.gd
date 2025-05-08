extends Node



var GetETHSWETHPrice: HTTPRequest
var wrGetETHSWETHPrice: WeakRef
signal get_eth_sweth_price_complete(message: Dictionary)


func get_eth_sweth_price() -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetETHSWETHPrice = prepared_http_req.request
	wrGetETHSWETHPrice = prepared_http_req.weakref

	var _connect: int = GetETHSWETHPrice.request_completed.connect(_on_GetPrice_request_completed)
	Utils.logger.info("Calling BKMREngine to get prices")
	var request_url: String = Utils.host + "/api/insight/eth/price"

	Utils.send_get_request(GetETHSWETHPrice, request_url)
	
	
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
