extends VBoxContainer

signal on_error_encountered(message: String)

var eth_price: float = 0.0
var eth_to_rsweth_rate: float = 0.0

@onready var line_edits: Array[Variant] = [%StakeAmount, %DollarValue, %ReceiveAmount, %DollarValue2, %ReceiveAmount]

#region 🔁 Lifecycle & Signal Setup

func _ready() -> void:
	connect_signals()

func connect_signals() -> void:
	var _1: int = User.user_data_received.connect(_on_user_data_received)
	var _2: int = Insight.get_eth_sweth_price_complete.connect(_on_get_eth_rsweth_price_complete)
	var _3: int = Onchain.get_eth_to_rsweth_rate_completed.connect(_on_get_eth_to_rsweth_rate_complete)
	var _4: int = Onchain.get_reward_rate_completed.connect(_on_get_reward_rate_completed)
	var _5: int = Onchain.stake_eth_completed.connect(on_stake_eth_completed)
	var _6: int = BiometricAuth.bio_auth_success.connect(_on_bio_auth_success)
	var _7: int = BiometricAuth.bio_auth_failed.connect(_on_bio_failed)

#endregion

#region 🔐 Biometric Auth Handling

func _on_bio_auth_success() -> void:
	if visible: 
		var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
		root_node.loading_start(true , "not bio")
		submit_staking_data()

func _on_bio_failed(_error: String) -> void:
	if visible: 
		var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
		root_node.loading_start(true, "bio")

#endregion

#region 👁️ Visibility & Data Refresh

func _on_visibility_changed() -> void:
	if visible:
		get_data()
	else:
		for line: Variant in line_edits:
			line.text = ""

func get_data() -> void:
	Auth.auto_login_user()
	Insight.get_eth_sweth_price()
	Onchain.get_eth_to_rsweth_rate()
	enable_disable_submit_button()

#endregion

#region ✅ Stake Completion Callback

func on_stake_eth_completed(message: Dictionary) -> void:
	if message.has("error"):
		on_error_encountered.emit("Error, please try again")
	await get_tree().create_timer(3.0).timeout
	
	%SubmitStakeButton.disabled = false
	on_error_encountered.emit("Staking successful!")
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false, "not bio")
	for line: Variant in line_edits:
		line.text = ""
	get_data()
	update_available_balance()
	
	
func update_available_balance() -> void:
	var user_eth_balance: float = %ETHBalance.text.replace(" ETH AVAILABLE", "").to_float()
	var new_eth_balance: float  = user_eth_balance - %StakeAmount.text.to_float()
	%ETHBalance.text = six_digit_balance_format(new_eth_balance) + " ETH AVAILABLE"
#endregion

#region 🧮 Stake Amount Input & Calculation

func _on_stake_amount_text_changed(stake_amount: String) -> void:
	if stake_amount.is_empty():
		var label: Array[Variant] = [%DollarValue, %ReceiveAmount, %DollarValue2]
		for text: Variant in label:
			text.text = ""
		return

	if not stake_amount.is_valid_float():
		return

	set_stake_values()

func set_stake_values() -> void:
	var stake_amount: String = %StakeAmount.text
	var amount: float = stake_amount.to_float()

	var usd_value: float = round(amount * eth_price * 100) / 100.0
	var formatted_usd: String = "$" + format_number_with_commas(usd_value)
	%DollarValue.text = formatted_usd
	%DollarValue2.text = formatted_usd

	var received_rsweth: float = amount * eth_to_rsweth_rate
	if received_rsweth == 0.0:
		%ReceiveAmount.text = "0"
	else:
		%ReceiveAmount.text = str(received_rsweth)

	enable_disable_submit_button()

func enable_disable_submit_button() -> void:
	%SubmitStakeButton.disabled = %StakeAmount.text.to_float() > %ETHBalance.text.to_float() or %StakeAmount.text.to_float() <= 0

#endregion

#region 👤 Wallet Balance Display

func _on_user_data_received(user_data: Dictionary) -> void:
	var eth_balance: float = user_data.walletData.ethBalance.to_float()
	var rsweth_balance: float = user_data.walletData.rsWETHBalance.to_float()
	%ETHBalance.text = six_digit_balance_format(eth_balance) + " ETH AVAILABLE"
	%RSWETHBalance.text = six_digit_balance_format(rsweth_balance) + " rswETH"

func six_digit_balance_format(balance: float) -> String:
	return String.num(balance, 6)

#endregion

#region 📈 ETH & rswETH Pricing / Rates

func _on_get_eth_rsweth_price_complete(prices: Dictionary) -> void:
	var _root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]

	if prices.has("error"):
		return

	if %StakeAmount.text.is_empty():
		eth_price = round(prices.ETHPrice * 100) / 100.0 
		return

	var stake_amount: float = %StakeAmount.text.to_float()
	var usd_value: float = round(prices.ETHPrice * stake_amount * 100) / 100.0
	eth_price = round(prices.ETHPrice * 100) / 100.0 

	if stake_amount == 0:
		usd_value = prices.ETHPrice

	%DollarValue.text = "$" + format_number_with_commas(usd_value)
	%DollarValue2.text = %DollarValue.text

func _on_get_eth_to_rsweth_rate_complete(rates: Dictionary) -> void:
	var _root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	_root_node.loading_start(false, "not bio")

	if rates.has("error"):
		return

	if %StakeAmount.text.is_empty():
		eth_to_rsweth_rate = rates.ethToRswETHRate
		return

	var stake_amount: float = %StakeAmount.text.to_float()
	var receive_amount: float = rates.ethToRswETHRate * stake_amount

	if receive_amount == 0.0:
		%ReceiveAmount.text = "0"
	else:
		%ReceiveAmount.text = str(receive_amount)

	eth_to_rsweth_rate = rates.ethToRswETHRate
	var rate: float = rates.rate
	var rounded_rate: float = round(rate * 10000) / 10000.0
	var padded: String = String.num(rounded_rate, 4)
	%ExchangeRate.text = "1 rswETH = " + padded

func _on_get_reward_rate_completed(_rate: Dictionary) -> void:
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false)

#endregion

#region 🧾 Submit Stake Button

func _on_submit_stake_button_pressed() -> void:
	var stake_amount: String = %StakeAmount.text.strip_edges()

	if stake_amount.is_empty():
		on_error_encountered.emit("Please enter an amount to stake.")
		return

	if not stake_amount.is_valid_float():
		on_error_encountered.emit("Invalid number format. Enter a valid ETH amount.")
		return

	var amount: float = stake_amount.to_float()

	if amount <= 0.0:
		on_error_encountered.emit("Amount must be greater than 0.")
		return

	var user_balance: float = %ETHBalance.text.replace(" ETH AVAILABLE", "").to_float()
	if amount > user_balance:
		on_error_encountered.emit("Insufficient ETH balance.")
		return

	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(true, "bio")

func submit_staking_data() -> void:
	%SubmitStakeButton.disabled = true
	var stake_amount: String = %StakeAmount.text
	Onchain.stake_eth(stake_amount)

#endregion

#region 🔘 Max Button

func _on_max_button_pressed() -> void:	
	var user_eth_balance: float = %ETHBalance.text.replace(" ETH AVAILABLE", "").to_float()
	%StakeAmount.text = str(user_eth_balance)
	set_stake_values()
	enable_disable_submit_button()

#endregion

#region 🧮 Formatting Helper

func format_number_with_commas(value: float, decimals: int = 2) -> String:
	var formatted: String = String.num(value, decimals)
	var parts: PackedStringArray = formatted.split(".")
	var int_part: String = parts[0]
	var dec_part: String = ""

	if parts.size() > 1:
		dec_part = "." + parts[1]

	var result: String = ""
	var counter: int = 0

	for i: int in range(int_part.length() - 1, -1, -1):
		result = int_part[i] + result
		counter += 1
		if counter % 3 == 0 and i > 0:
			result = "," + result

	return result + dec_part

#endregion
