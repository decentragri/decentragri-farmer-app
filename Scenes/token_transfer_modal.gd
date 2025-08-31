extends VBoxContainer

var receiver_address: String = ""
var amount: String = ""
var selected_token_price: float = 0.0

var token_name: String



func _ready() -> void:
	var _1: int = Onchain.transfer_token_completed.connect(_on_transfer_token_completed)
	
	
func _on_transfer_token_completed(message: Dictionary) -> void:
	Auth.auto_login_user()
	if message.has("error"):
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Transfer failed: " + message.error)
	else:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Transfer successful!")


func _on_back_button_pressed() -> void:
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = false
	visible = false
	reset_fields()
	
	
func reset_fields() -> void:
	for field: Variant in get_tree().get_nodes_in_group(&"TokenTransferModalFields"):
		field.text = ""
	receiver_address = ""
	amount = ""
	selected_token_price = 0.0
	%ErrorLabel.text = ""
	%PesoEquivalent.text = "≈ ₱0.00"
	%TransferButton.disabled = true
	
	
func _on_wallet_container_wallet_token_button_pressed(token_data: Dictionary) -> void:
	visible = true
	for modal_container: VBoxContainer in get_tree().get_nodes_in_group(&"ModalContainer"):
		modal_container.visible = true
	
	%TokenIcon.texture = token_data.texture
	%TokenIconMain.texture = token_data.texture
	%TokenTransferLabel.text = "Transfer " + token_data.name
	

	token_name = token_data.name.to_upper()
	var chain_name: String = get_chain_name(str(token_data.name))

	%TokenName.text = token_name + " TOKEN (" + chain_name + " CHAIN)"
	%Balance.text = token_data.balance
	selected_token_price = token_data.price
	#%PesoEquivalent.text = str(token_data.price)
	
	
func _on_receiver_address_text_changed(address: String) -> void:
	receiver_address = address.strip_edges()
	_validate_inputs()
	
	
func _on_amount_text_changed(token_amount: String) -> void:
	amount = token_amount.strip_edges()
	_validate_inputs()
	_update_peso_equivalent()
	
	
func _validate_inputs() -> void:
	var valid_address: bool = _is_valid_eth_address(receiver_address)
	var valid_amount: bool = _is_valid_amount(amount)

	if receiver_address.is_empty():
		%ErrorLabel.text = "Address is required"
	elif not valid_address:
		%ErrorLabel.text = "Invalid Ethereum address"
	elif amount.is_empty():
		%ErrorLabel.text = "Amount is required"
	elif not valid_amount:
		%ErrorLabel.text = "Amount must be a positive number"
	else:
		%ErrorLabel.text = ""

	%TransferButton.disabled = not (valid_address and valid_amount)
	
	
func _update_peso_equivalent() -> void:
	if _is_valid_amount(amount):
		var peso_value: float = amount.to_float() * selected_token_price
		%PesoEquivalent.text = "≈ ₱" + Utils.format_balance( String.num(peso_value * 56.5, 2))
	else:
		%PesoEquivalent.text = "≈ ₱0.00"
	
	
func _is_valid_eth_address(address: String) -> bool:
	var regex: RegEx = RegEx.new()
	if regex.compile("^0x[a-fA-F0-9]{40}$") != OK:
		push_error("Failed to compile regex for Ethereum address validation")
		return false
	return regex.search(address) != null
	
	
func _is_valid_amount(value: String) -> bool:
	return value.is_valid_float() and value.to_float() > 0.0
	
	
func get_chain_name(name_token: String) -> String:
	var upper_name: String = name_token.to_upper()
	match upper_name:
		"DAGRI":
			return "BASE"
		"FDAGRI":
			return "BASE"
		_:
			return upper_name


func _on_transfer_button_pressed() -> void:
	# Get values from UI
	var receiver: String = %RecipientAddress.text.strip_edges()
	var amount_text: String = %Amount.text.strip_edges()
	
	# Validate receiver address
	if receiver.is_empty():
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Error: Receiver address cannot be empty")
		return
	
	if not _is_valid_eth_address(receiver):
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Error: Invalid Ethereum address format")
		return
	
	# Validate amount
	if amount_text.is_empty():
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Error: Amount cannot be empty")
		return
	
	if not _is_valid_amount(amount_text):
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Error: Amount must be a positive number")
		return
	
	# Validate token name
	if token_name.is_empty():
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Error: Token name is missing")
		return
	
	# Check if amount exceeds balance (optional additional check)
	var balance_text: String = %Balance.text.strip_edges()
	if not balance_text.is_empty() and balance_text.is_valid_float():
		var amount_float: float = amount_text.to_float()
		var balance_float: float = balance_text.to_float()
		if amount_float > balance_float:
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Error: Insufficient balance. Amount exceeds available balance")
			return
	
	# All validations passed, create transfer data
	var token_transfer_data: Dictionary[String, Variant] = {
		"receiver": receiver,
		"tokenName": token_name,
		"amount": amount_text
	}
	
	print("Transfer data validated: ", token_transfer_data)
	
	# Check network connectivity and handle offline/online scenarios
	if OS.get_name() == "Android":
		if NetworkState.hasNetwork():
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("Token transfer in progress...")
			Onchain.transfer_token(token_transfer_data)
		else:
			# Save transaction data offline for later sync
			token_transfer_data["pending"] = true
			token_transfer_data["transactionType"] = "token_transfer"
			token_transfer_data["timestamp"] = Time.get_unix_time_from_system()
			RealmDB.save_data(JSON.stringify(token_transfer_data), "TransactionData")
			for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
				main.message_box("No internet connection. Transaction saved offline.")
	else:
		# For non-Android platforms, attempt direct transfer
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Token transfer in progress...")
		Onchain.transfer_token(token_transfer_data)
	
	_on_back_button_pressed()
