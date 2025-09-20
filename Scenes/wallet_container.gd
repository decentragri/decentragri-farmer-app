extends VBoxContainer

signal wallet_token_button_pressed(token_data: Dictionary[String, Variant])


var eth_price: float
var swell_price: float
var dagri_price: float
var fdagri_price: float

func _ready() -> void:
	var _1: int = User.user_data_received.connect(_on_user_data_received)
	
	
func _on_visibility_changed() -> void:
	if visible:
		for button: TextureButton in get_tree().get_nodes_in_group(&"WalletTokenButton"):
			if button.pressed.is_connected(_on_token_button_pressed):
				button.pressed.disconnect(_on_token_button_pressed)
		Auth.auto_login_user()
	else:
		pass
	
	
func connect_signals() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group(&"WalletTokenButton"):
		var vbox: VBoxContainer = button.get_parent().get_node("VBoxContainer")
		
		# Capture values early for closure binding
		var token_texture: Texture = vbox.get_child(1).texture
		var balance: String = vbox.get_child(2).text
		var label_name: String = vbox.get_child(2).name
		
		if not button.pressed.is_connected(_on_token_button_pressed):
		# Connect button pressed signal and bind the values
			var _2: int = button.pressed.connect(_on_token_button_pressed.bind(token_texture, balance, label_name))
			
	for button: TextureButton in get_tree().get_nodes_in_group(&"WalletCopyButton"):
		if not button.pressed.is_connected(_on_wallet_copy_button_pressed):
			var _2: int = button.pressed.connect(_on_wallet_copy_button_pressed.bind(button))
	
	
func _on_wallet_copy_button_pressed(button: TextureButton) -> void:
	var username_or_wallet_line_edit: LineEdit = button.get_parent()
	var username_or_wallet_address: String = username_or_wallet_line_edit.text
	DisplayServer.clipboard_set(username_or_wallet_address)
	button.texture_normal = preload("res://Assets/Icons/confirm_button.png")
	var _1: int = get_tree().create_timer(1.5).timeout.connect(
		func() -> void:
			button.texture_normal = preload("res://Assets/Icons/copy_icon.png")
	)
	
	
func _on_token_button_pressed(token_texture: Texture, balance: String, label_name: String) -> void:
	print(label_name)
	emit_token_signal(token_texture, balance, label_name)
	
	
func emit_token_signal(token_texture: Texture, balance: String, label_name: String) -> void:
	var price: float = 0.0
	var token_name: String
	match label_name:
		"ETHBalance":
			price = eth_price
			token_name = "ETH"
		"rswETHBalance":
			price = eth_price
			token_name = "rswETH"
		"SwellBalance":
			price = swell_price
			token_name = "SWELL"
		"DagriBalance":
			price = dagri_price
			token_name = "DAGRI"
		"FdagriBalance":
			price = fdagri_price
			token_name = "FDAGRI"
		_:
			
			price = 0.0
	wallet_token_button_pressed.emit({
		"texture": token_texture,
		"balance": balance,
		"price": price,
		"name": token_name
	})
		
		
func _on_user_data_received(user_data: Dictionary) -> void:
	# Handle offline mode - show appropriate placeholders
	if user_data.has("offline") and user_data.offline:
		%ETHBalance.text = "ETH ---.--"
		%rswETHBalance.text = "rswETH ---.--"
		%FdagriBalance.text = "FDAGRI ---.--"
		%DagriBalance.text = "DAGRI ---.--"
		%Username.text = user_data.get("username", "")
		%SmartWalletAddress.text = "Offline Mode - No Wallet Access"
		connect_signals()
		return
	
	# Handle online mode with full wallet data
	var eth_balance: float = user_data.walletData.ethBalance.to_float()
	var rsweth_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var fdagri_balance: float = user_data.walletData.farmerCreditTokenBalance.to_float()
	#var swell_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var dagri_balance: float = user_data.walletData.dagriBalance.to_float()
	
	eth_price = user_data.walletData.ethPriceUSD
	swell_price = user_data.walletData.swellPriceUSD
	dagri_price = user_data.walletData.dagriPriceUSD
	
	%ETHBalance.text = "ETH " + four_digit_balance_format(eth_balance)
	%rswETHBalance.text = "rswETH " + four_digit_balance_format(rsweth_balance)
	#%SwellBalance.text = "SWELL " + four_digit_balance_format(swell_balance)
	%FdagriBalance.text = "FDAGRI " + four_digit_balance_format(fdagri_balance)
	%DagriBalance.text = "DAGRI " + four_digit_balance_format(dagri_balance) 

	%Username.text = User.username
	%SmartWalletAddress.text = User.wallet_address
	connect_signals()
func four_digit_balance_format(balance: float) -> String:
	return "0" if balance == 0.0 else String.num(balance, 5)
