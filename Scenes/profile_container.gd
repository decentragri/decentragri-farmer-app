extends VBoxContainer
signal on_error_encountered(message: String)
signal wallet_token_button_pressed(token_data: Dictionary[String, Variant])

var eth_price: float
var swell_price: float
var dagri_price: float


func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	var _1: int = User.user_data_received.connect(_on_user_data_received)
	for button: TextureButton in get_tree().get_nodes_in_group(&"WalletCopyButton"):
		var _2: int = button.pressed.connect(_on_wallet_copy_button_pressed.bind(button))
	
	
func get_data() -> void:
	Auth.auto_login_user()
	
	
func _on_wallet_copy_button_pressed(button: TextureButton) -> void:
	var username_or_wallet_line_edit: LineEdit = button.get_parent()
	var username_or_wallet_address: String = username_or_wallet_line_edit.text
	DisplayServer.clipboard_set(username_or_wallet_address)
	on_error_encountered.emit("Successfully copied " + button.name)
	
func _on_user_data_received(user_data: Dictionary) -> void:
	%UsernameLogin.text = user_data.get("username", "")
	
	# Handle offline mode - show appropriate placeholders
	if user_data.has("offline") and user_data.offline:
		%SmartWalletAddress.text = "Offline Mode - No Wallet Access"
		%ETHBalance.text = "ETH ---.--"
		%RSWETHBalance.text = "rswETH ---.--"
		%SwellBalance.text = "SWELL ---.--"
		%DecentraBalance.text = "DAGRI ---.--"
		return
	
	# Handle online mode with full wallet data
	%SmartWalletAddress.text = user_data.walletAddress
	
	var eth_balance: float = user_data.walletData.ethBalance.to_float()
	var rsweth_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var swell_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var dagri_balance: float = user_data.walletData.dagriBalance.to_float()
	
	eth_price = user_data.walletData.ethPriceUSD
	swell_price = user_data.walletData.swellPriceUSD
	dagri_price = user_data.walletData.dagriPriceUSD
	
	%ETHBalance.text = "ETH " + four_digit_balance_format(eth_balance)
	%RSWETHBalance.text = "rswETH " + four_digit_balance_format(rsweth_balance)
	%SwellBalance.text = "SWELL " + four_digit_balance_format(swell_balance)
	%DecentraBalance.text = "DAGRI " + four_digit_balance_format(dagri_balance) 
	
	
func four_digit_balance_format(balance: float) -> String:
	return String.num(balance, 4)


func _on_eth_button_pressed() -> void:
	wallet_token_button_pressed.emit({ "texture": %ETHTexture.texture, "balance": %ETHBalance.text, "price": eth_price })


func _on_rsw_eth_button_pressed() -> void:
	wallet_token_button_pressed.emit({ "texture": %RSWETHTexture.texture, "balance": %RSWETHBalance.text, "price": eth_price })


func _on_swell_button_pressed() -> void:
	wallet_token_button_pressed.emit({ "texture": %SwellTexture .texture, "balance": %SwellBalance.text, "price": swell_price })


func _on_dagri_button_pressed() -> void:
	wallet_token_button_pressed.emit({ "texture": %DagriTexture.texture, "balance": %DecentraBalance.text, "price": dagri_price })


func _on_visibility_changed() -> void:
	get_data()


func _on_sync_button_pressed() -> void:
	if OS.get_name() == "Android":
		NetworkState.manual_sync()
	else:
		on_error_encountered.emit("Sync feature only available on Android")
