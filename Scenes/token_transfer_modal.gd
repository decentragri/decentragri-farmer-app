extends VBoxContainer

var receiver_address: String = ""
var amount: String = ""
var selected_token_price: float = 0.0

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

	var token_name: String = token_data.name.to_upper()
	var chain_name: String = get_chain_name(str(token_data.name))

	%TokenName.text = token_name + " TOKEN (" + chain_name + " CHAIN)"
	%Balance.text = token_data.balance


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
		%PesoEquivalent.text = "≈ $" + String.num(peso_value, 2)
	else:
		%PesoEquivalent.text = "≈ $0.00"

func _is_valid_eth_address(address: String) -> bool:
	var regex: RegEx = RegEx.new()
	if regex.compile("^0x[a-fA-F0-9]{40}$") != OK:
		push_error("Failed to compile regex for Ethereum address validation")
		return false
	return regex.search(address) != null

func _is_valid_amount(value: String) -> bool:
	return value.is_valid_float() and value.to_float() > 0.0

func get_chain_name(token_name: String) -> String:
	var upper_name: String = token_name.to_upper()
	
	match upper_name:
		"DAGRI":
			return "SWELL"
		"RSWETH":
			return "ETH"
		_:
			return upper_name
