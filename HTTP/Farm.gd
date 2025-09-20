extends Node

# Cache configuration
const FARM_CACHE_KEY: String = "cached_farms"
const FARM_CACHE_TIMESTAMP_KEY: String = "cached_farms_timestamp"
const CACHE_EXPIRY_HOURS: int = 24  # Cache expires after 24 hours
const MAX_CACHED_FARMS: int = 100   # Limit cache size

var CreateFarm: HTTPRequest
var wrCreateFarm: WeakRef
signal create_farm_complete(message: Dictionary[String, String])

var GetFarms: HTTPRequest
var wrGetFarms: WeakRef
signal get_farms_complete(farm: Array[Dictionary])

var GetFarmData: HTTPRequest
var wrGetFarmData: WeakRef
signal get_farm_data_complete(farm: Dictionary)

var SellFarm: HTTPRequest
var wrSellFarm: WeakRef
signal sell_farm_complete(message: Dictionary[String, String])

# Cache management
var cached_farms: Array[Dictionary] = []
var cache_timestamp: float = 0.0
var is_loading_from_server: bool = false


func _ready() -> void:
	# Load cached farms on startup
	load_farms_from_cache()


#region Cache Management

func load_farms_from_cache() -> void:
	"""Load farms from RealmDB cache"""
	Utils.logger.info("Loading farms from cache...")
	
	# Load cached farms
	var cached_data: Variant = RealmDB.get_data(FARM_CACHE_KEY)
	var cached_time: Variant = RealmDB.get_data(FARM_CACHE_TIMESTAMP_KEY)
	
	if cached_data != null and cached_time != null:
		if cached_data is Array:
			# Safe casting with validation
			var temp_array: Array = cached_data
			cached_farms = []
			for item: Variant in temp_array:
				if item is Dictionary:
					cached_farms.append(item)
		else:
			cached_farms = []
		cache_timestamp = float(str(cached_time))
		
		var current_time: float = Time.get_unix_time_from_system()
		var cache_age_hours: float = (current_time - cache_timestamp) / 3600.0
		
		Utils.logger.info("Found cached farms: %d items, age: %.1f hours" % [cached_farms.size(), cache_age_hours])
		
		# Always emit cached data first for instant UI response
		if cached_farms.size() > 0:
			get_farms_complete.emit(cached_farms)
		
		# Check if we need to refresh from server
		if cache_age_hours > CACHE_EXPIRY_HOURS:
			Utils.logger.info("Cache expired, will refresh from server")
		elif not Auth.offline_mode and OS.get_name() == "Android" and NetworkState.hasNetwork():
			# Background refresh if online (silent update)
			Utils.logger.info("Background refresh from server")
			get_farms()  # Call existing method
		elif not Auth.offline_mode:
			# Non-Android or no network state check
			get_farms()  # Call existing method
	else:
		Utils.logger.info("No cached farms found")
		cached_farms = []
		cache_timestamp = 0.0


func save_farms_to_cache(farms: Array[Dictionary]) -> void:
	"""Save farms to RealmDB cache with timestamp"""
	Utils.logger.info("Saving %d farms to cache..." % farms.size())
	
	# Limit cache size to prevent memory issues
	var farms_to_cache: Array[Dictionary] = farms
	if farms_to_cache.size() > MAX_CACHED_FARMS:
		farms_to_cache = farms_to_cache.slice(0, MAX_CACHED_FARMS)
		Utils.logger.info("Truncated cache to %d farms" % MAX_CACHED_FARMS)
	
	# Add cache metadata to each farm
	var current_time: float = Time.get_unix_time_from_system()
	for farm: Dictionary in farms_to_cache:
		farm["_cached_at"] = current_time
	
	# Save to RealmDB
	RealmDB.save_data(JSON.stringify(farms_to_cache), FARM_CACHE_KEY)
	RealmDB.save_data(str(current_time), FARM_CACHE_TIMESTAMP_KEY)
	
	cached_farms = farms_to_cache
	cache_timestamp = current_time
	
	Utils.logger.info("Farms cached successfully")


func clear_farm_cache() -> void:
	"""Clear the farm cache"""
	Utils.logger.info("Clearing farm cache...")
	RealmDB.clear_data(FARM_CACHE_KEY)
	RealmDB.clear_data(FARM_CACHE_TIMESTAMP_KEY)
	cached_farms = []
	cache_timestamp = 0.0


func get_cache_info() -> Dictionary:
	"""Get information about the current cache state"""
	var current_time: float = Time.get_unix_time_from_system()
	var cache_age_hours: float = (current_time - cache_timestamp) / 3600.0 if cache_timestamp > 0.0 else -1.0
	
	return {
		"cached_count": cached_farms.size(),
		"cache_age_hours": cache_age_hours,
		"is_expired": cache_age_hours > CACHE_EXPIRY_HOURS,
		"last_cached": cache_timestamp
	}


func refresh_farms_cache() -> void:
	"""Force refresh farms from server - useful for pull-to-refresh"""
	Utils.logger.info("Force refreshing farms cache...")
	get_farms(true)


func get_cached_farms() -> Array[Dictionary]:
	"""Get current cached farms without triggering network request"""
	return cached_farms

#endregion


#region Farm Data Fetching


func create_farm(farm_data: Dictionary[String, Variant]) -> void:
	# Prepare an HTTP request for fetching leaderboard data.
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	CreateFarm = prepared_http_req.request
	wrCreateFarm = prepared_http_req.weakref

	# Log the initiation of the request to retrieve leaderboard data.	
	Utils.logger.info("Call to create farm")
	
	# Construct the request URL for fetching leaderboard data.
	var request_url: String = Utils.host + "/api/create/farm"

	# Send the POST request using the prepared URL with retry.
	Utils.send_post_request_with_retry(CreateFarm, request_url, farm_data, _on_create_farm_request_completed)


func _on_create_farm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body is Dictionary:
				if json_body.has("error"):
					create_farm_complete.emit({ "error": json_body.error })
				else:
					# Farm created successfully - invalidate cache
					Utils.logger.info("Farm created successfully, invalidating cache")
					clear_farm_cache()
					create_farm_complete.emit(json_body)
					# Optionally refresh farms list
					get_farms(true)
		else:
			create_farm_complete.emit({ "error": "Unknown server error" })
	else:
		create_farm_complete.emit({ "error": "Unknown server error" })
		
		
		
func get_farms(force_refresh: bool = false) -> void:
	"""
	Get farms with intelligent caching
	- If force_refresh=false: Return cached data immediately if available, then optionally refresh
	- If force_refresh=true: Always fetch from server and update cache
	- If offline: Always return cached data
	"""
	Utils.logger.info("get_farms called, force_refresh: %s" % force_refresh)
	
	# Check if we're offline
	if Auth.offline_mode:
		Utils.logger.info("Offline mode: returning cached farms only")
		if cached_farms.size() > 0:
			get_farms_complete.emit(cached_farms)
		else:
			get_farms_complete.emit([])
		return
	
	# Check network connectivity for Android
	if OS.get_name() == "Android" and not NetworkState.hasNetwork():
		Utils.logger.info("No network: returning cached farms only")
		if cached_farms.size() > 0:
			get_farms_complete.emit(cached_farms)
		else:
			get_farms_complete.emit([])
		return
	
	# If force refresh or no cache, fetch from server
	if force_refresh or cached_farms.size() == 0:
		_fetch_farms_from_server()
		return
	
	# Return cached data immediately for instant response
	Utils.logger.info("Returning cached farms for instant response")
	get_farms_complete.emit(cached_farms)
	
	# Check if cache needs refreshing
	var cache_info: Dictionary = get_cache_info()
	if cache_info.is_expired:
		Utils.logger.info("Cache expired, refreshing in background")
		_fetch_farms_from_server()


func _fetch_farms_from_server() -> void:
	"""Internal method to fetch farms from server"""
	if is_loading_from_server:
		Utils.logger.info("Already loading from server, skipping request")
		return
	
	is_loading_from_server = true
	
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetFarms = prepared_http_req.request
	wrGetFarms = prepared_http_req.weakref

	Utils.logger.info("Fetching farms from server...")
	
	var request_url: String = Utils.host + "/api/list/farm"
	# Use retry-enabled GET request
	Utils.send_get_request_with_retry(GetFarms, request_url, _on_get_farms_request_completed)


func _on_get_farms_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	is_loading_from_server = false
	
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	# Check if the server update was successful.
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			
			if json_body.has("error"):
				Utils.logger.error("Server error getting farms: %s" % json_body.error)
				# Return cached data if available on server error
				if cached_farms.size() > 0:
					Utils.logger.info("Server error, returning cached farms")
					get_farms_complete.emit(cached_farms)
				else:
					get_farms_complete.emit([])
			else:
				# Successful response - save to cache and emit
				if json_body is Array:
					var farms_array: Array[Dictionary] = []
					for item: Variant in json_body:
						if item is Dictionary:
							farms_array.append(item)
					
					Utils.logger.info("Successfully fetched %d farms from server" % farms_array.size())
					save_farms_to_cache(farms_array)
					get_farms_complete.emit(farms_array)
				else:
					Utils.logger.error("Invalid farms data format from server")
					# Return cached data on invalid format
					if cached_farms.size() > 0:
						get_farms_complete.emit(cached_farms)
					else:
						get_farms_complete.emit([])
		else:
			Utils.logger.error("Failed to parse farms response")
			# Return cached data on parse error
			if cached_farms.size() > 0:
				get_farms_complete.emit(cached_farms)
			else:
				get_farms_complete.emit([])
	else:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		Utils.logger.error("HTTP error getting farms: %s" % str(json_body))
		# Return cached data on HTTP error
		if cached_farms.size() > 0:
			Utils.logger.info("HTTP error, returning cached farms")
			get_farms_complete.emit(cached_farms)
		else:
			get_farms_complete.emit([])


func get_farm_data(farm_id: String) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	GetFarmData = prepared_http_req.request
	wrGetFarmData = prepared_http_req.weakref

	Utils.logger.info("Call to get farm data")
	
	var request_url: String = Utils.host + "/api/data/farm/" + farm_id
	Utils.send_get_request_with_retry(GetFarmData, request_url, _on_get_farm_data_request_completed)


func _on_get_farm_data_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:	
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				get_farm_data_complete.emit({ "error": json_body.error })
			else:
				get_farm_data_complete.emit(json_body)
		else:
			get_farm_data_complete.emit({ "error": "Unknown server error" })
	else:
		get_farm_data_complete.emit({ "error": "Unknown server error" })


func sell_farm(farm_id: String) -> void:
	var prepared_http_req: Dictionary = Utils.prepare_http_request()
	SellFarm = prepared_http_req.request
	wrSellFarm = prepared_http_req.weakref

	Utils.logger.info("Call to sell farm")
	
	var request_url: String = Utils.host + "/api/sell/farm/" + farm_id
	Utils.send_post_request_with_retry(SellFarm, request_url, {}, _on_sell_farm_request_completed)
	
	
func _on_sell_farm_request_completed(_result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:	
	# Check the HTTP response status.
	var status_check: bool = Utils.logger.check_http_response(response_code, headers, body)
	
	if status_check:
		var json_body: Variant = JSON.parse_string(body.get_string_from_utf8())
		if json_body != null:
			if json_body.has("error"):
				sell_farm_complete.emit({ "error": json_body.error })
			else:
				# Farm sold successfully - invalidate cache
				Utils.logger.info("Farm sold successfully, invalidating cache")
				clear_farm_cache()
				sell_farm_complete.emit(json_body)
				# Optionally refresh farms list
				get_farms(true)
		else:
			sell_farm_complete.emit({ "error": "Unknown server error" })
	else:
		sell_farm_complete.emit({ "error": "Unknown server error" })
