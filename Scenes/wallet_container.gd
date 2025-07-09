extends VBoxContainer

signal wallet_token_button_pressed(token_data: Dictionary[String, Variant])


var eth_price: float
var swell_price: float
var dagri_price: float

func _ready() -> void:
	connect_signals()
	
func _on_visibility_changed() -> void:
	Auth.auto_login_user()
	
	
func connect_signals() -> void:
	var _1: int = User.user_data_received.connect(_on_user_data_received)

	for button: TextureButton in get_tree().get_nodes_in_group(&"WalletTokenButton"):
		var vbox: VBoxContainer = button.get_parent().get_node("VBoxContainer")
		
		# Capture values early for closure binding
		var token_texture: Texture = vbox.get_child(1).texture
		var balance: String = vbox.get_child(2).text
		var label_name: String = vbox.get_child(2).name

		# Connect button pressed signal and bind the values
		var _2: int = button.pressed.connect(_on_token_button_pressed.bind(token_texture, balance, label_name))
		
	for button: TextureButton in get_tree().get_nodes_in_group(&"WalletCopyButton"):
		var _2: int = button.pressed.connect(_on_wallet_copy_button_pressed.bind(button))
	
	
func _on_wallet_copy_button_pressed(button: TextureButton) -> void:
	var username_or_wallet_line_edit: LineEdit = button.get_parent()
	var username_or_wallet_address: String = username_or_wallet_line_edit.text
	DisplayServer.clipboard_set(username_or_wallet_address)


func _on_token_button_pressed(token_texture: Texture, balance: String, label_name: String) -> void:
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
		_:
			price = 0.0

	wallet_token_button_pressed.emit({
		"texture": token_texture,
		"balance": balance,
		"price": price,
		"name": token_name
	})
		
		
func _on_user_data_received(user_data: Dictionary) -> void:
	var eth_balance: float = user_data.walletData.ethBalance.to_float()
	var rsweth_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var swell_balance: float = user_data.walletData.rsWETHBalance.to_float()
	var dagri_balance: float = user_data.walletData.dagriBalance.to_float()
	
	eth_price = user_data.walletData.ethPriceUSD
	swell_price = user_data.walletData.swellPriceUSD
	dagri_price = user_data.walletData.dagriPriceUSD
	
	%ETHBalance.text = "ETH " + four_digit_balance_format(eth_balance)
	%rswETHBalance.text = "rswETH " + four_digit_balance_format(rsweth_balance)
	%SwellBalance.text = "SWELL " + four_digit_balance_format(swell_balance)
	%DagriBalance.text = "DAGRI " + four_digit_balance_format(dagri_balance) 
	
	%Username.text = User.username
	%SmartWalletAddress.text = User.wallet_address
	
	

func four_digit_balance_format(balance: float) -> String:
	return "0" if balance == 0.0 else String.num(balance, 4)


func _on_username_copy_pressed() -> void:
	pass # Replace with function body.


func _on_wallet_address_copy_pressed() -> void:
	pass # Replace with function body.
