extends Control

signal on_send_button_pressed(send_data: Dictionary)
signal on_error_encountered(message: String)

const history_slot: PackedScene = preload("res://Popups/transaction_history_entry.tscn")
const chains: Dictionary[String, String] = {
	"rswETH": "1",
	"ETH": "1",
	"SWELL": "1923",
	"DAGRI": "1923"
}

var price: int

#region 🔁 Lifecycle & Initialization

func _ready() -> void:
	# Handle offline mode - disable wallet functionality
	if User.wallet_address.is_empty():
		%WalletAddress.text = "Offline Mode - No Wallet Access"
		# You might want to disable token transfer buttons here
	else:
		%WalletAddress.text = User.wallet_address
	connect_signals()

func connect_signals() -> void:
	var _1: int = Insight.get_last_transactions_complete.connect(_on_get_last_transactions_complete)
	var _2: int = BiometricAuth.bio_auth_success.connect(_on_bio_auth_success)
	var _3: int = BiometricAuth.bio_auth_failed.connect(_on_bio_failed)
	var _4: int = Onchain.transfer_token_completed.connect(_on_transfer_token_completed)
	numpad_buttons()

func numpad_buttons() -> void:
	for numpad_button: Button in get_tree().get_nodes_in_group(&"NumpadButtons"):
		var _1: int = numpad_button.pressed.connect(_on_numpad_button_pressed.bind(numpad_button))

#endregion

#region ✅ Token Transfer Flow

func _on_send_button_pressed() -> void:
	%SelectTransactionContainer.visible = false
	%SendTransactionContainer.visible = true
	on_send_button_pressed.emit()

func _on_confirm_button_pressed() -> void:
	BiometricAuth.start_biometrics_auth()

func _on_bio_auth_success() -> void:
	if %Numpad.visible:
		send_token_transfer_data()

func send_token_transfer_data() -> void:
	var token_name: String = %Currency.text
	var token_transfer_data: Dictionary[String, String] = {
		"receiver": %RecipientAddress.text,
		"tokenName": token_name,
		"amount": %SendAmountValue.text
	}
	print(token_transfer_data)
	#Onchain.transfer_token(token_transfer_data)
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(true)

func _on_transfer_token_completed(message: Dictionary) -> void:
	if message.has("error"):
		on_error_encountered.emit(message.error + " please try again")
		return
	var root_node: Control = get_tree().get_nodes_in_group(&"RootNode")[0]
	root_node.loading_start(false)
	on_error_encountered.emit("Token successfully sent")

func _on_bio_failed(_message: String) -> void:
	on_error_encountered.emit("Error. Please try again")

#endregion

#region 🧮 Amount Entry & Numpad

func _on_numpad_button_pressed(button: Button) -> void:
	var char_pressed: String = button.text
	var current_text: String = %SendAmountValue.text

	match char_pressed:
		"<":
			if current_text.length() > 0:
				%SendAmountValue.text = current_text.left(current_text.length() - 1)
		".":
			if not current_text.contains("."):
				%SendAmountValue.text += "."
		_:
			if char_pressed.is_valid_int():
				%SendAmountValue.text += char_pressed

	enable_disable_confirm_button()
	%SentTokenValue.text = "$" + str(int(price) * $%SendAmountValue.text.to_int())

func _on_max_amount_button_pressed() -> void:
	%SendAmountValue.text = %TokenAmount.text
	enable_disable_confirm_button()
	%SentTokenValue.text = "$" + str(int(price) * $%SendAmountValue.text.to_int())

func _on_send_amount_value_text_changed() -> void:
	pass

func enable_disable_confirm_button() -> void:
	var entered_text: String = %SendAmountValue.text.strip_edges()
	var token_amount_text: String = %TokenAmount.text.strip_edges()
	var entered_amount: float = entered_text.to_float()
	var owned_amount: float = token_amount_text.to_float()

	if entered_text.is_valid_float() and entered_amount > 0.0 and entered_amount <= owned_amount:
		%ConfirmButton.disabled = false
	else:
		%ConfirmButton.disabled = true

#endregion

#region 🏷️ Token Info Setup

func token_data(data_token: Dictionary) -> void:
	visible = true
	%SelectTransactionContainer.visible = true

	var chain: String = data_token.balance.split(" ")[0]
	%Currency.text = chain
	%CurrencyIcon.texture = data_token.texture

	var raw_balance: String = data_token.balance.split(" ")[1]
	if raw_balance == "0.0":
		raw_balance = "0"
	%Balance.text = raw_balance

	var balance: String = %Balance.text
	price = data_token.price
	var icon_texture: Texture = data_token.texture
	%BalanceValue.text = "$" + str(int(balance) * price)

	set_chain_name(chain)
	set_icon_texture(icon_texture)

func set_chain_name(chain: String) -> void:
	var chain_symbol: String
	match chain:
		"rswETH", "ETH":
			chain_symbol = "ETH"
		"SWELL":
			chain_symbol = "SWELL"
		"DAGRI":
			chain_symbol = "SWELL"

	%ChainName.text = chain_symbol
	get_transactions()

func set_icon_texture(texture_icon: Texture) -> void:
	%CurrencyIcon.texture = texture_icon

#endregion

#region 🔎 Address Input / Validation

func _on_recipient_address_text_changed() -> void:
	var address: String = %RecipientAddress.text.strip_edges()
	var is_valid: bool = is_valid_evm_address(address)
	%ConfirmAddressButton.disabled = not is_valid

func _on_paste_button_pressed() -> void:
	var clip_board_text: String = DisplayServer.clipboard_get()
	$%RecipientAddress.text = clip_board_text
	var address: String = %RecipientAddress.text.strip_edges()
	var is_valid: bool = is_valid_evm_address(address)
	%ConfirmAddressButton.disabled = not is_valid

func is_valid_evm_address(address: String) -> bool:
	if address.length() != 42:
		return false
	if not address.begins_with("0x"):
		return false
	var hex_part: String = address.substr(2)
	for c: String in hex_part:
		if not c.is_valid_hex_number():
			return false
	return true

func _on_clear_button_pressed() -> void:
	%RecipientAddress.text = ""

func _on_confirm_address_button_pressed() -> void:
	%SendAmountValue.grab_focus()
	%CurrencySign.text = %Currency.text
	%TokenAmount.text = %Balance.text
	%TokenSymbol.text = %Currency.text
	%EnterAmountContainer.visible = true
	%SendTransactionContainer.visible = false
	%Numpad.visible = true

#endregion

#region ⬅️ Navigation & UI State


func _on_back_button_pressed() -> void:
	visible = false
	%Numpad.visible = false

func _on_send_back_button_pressed() -> void:
	visible = false
	%EnterAmountContainer.visible = false
	%SendTransactionContainer.visible = false
	%RecipientAddress.text = ""
	%Numpad.visible = false
	%SentTokenValue.text = ""
	%SendAmountValue.text = ""

func _on_send_transaction_container_visibility_changed() -> void:
	if visible:
		%RecipientAddress.grab_focus()
	else:
		%RecipientAddress.release_focus()
		%RecipientAddress.text = ""

func _on_copy_button_pressed() -> void:
	var wallet_address: String = %WalletAddress.text
	DisplayServer.clipboard_set(wallet_address)
	on_error_encountered.emit("Successfully copied wallet address")

#endregion

#region 📈 Transaction History

func get_transactions() -> void:
	var chain_id: String = chains[%ChainName.text]
	Insight.get_last_transaction(User.wallet_address, chain_id)

func _on_get_last_transactions_complete(transactions: Dictionary) -> void:
	if transactions.has("error"):
		return

#endregion
