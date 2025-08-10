extends VBoxContainer




func _ready() -> void:
	connect_signals()
	Staking.get_stake_info()
	
	
func connect_signals() -> void:
	var _1: int = User.user_data_received.connect(_on_user_data_received)
	var _2: int = Staking.get_stake_info_complete.connect(_on_get_stake_info_complete)
	var _3: int = Staking.stake_tokens_complete.connect(_on_stake_tokens_complete)
	var _4: int = Staking.claim_rewards_complete.connect(_on_claim_rewards_complete)


func _on_claim_rewards_complete(result: Dictionary) -> void:
	if result.has("error"):
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Claiming rewards failed: " + str(result.error))
	else:
		%RewardReceiveAmount.text = "0"
		Utils.logger.info("Claiming rewards successful: " + str(result))
		# Refresh the stake info to show updated data
		Staking.get_stake_info()
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Claiming rewards successful!")


func _on_user_data_received(user_data: Dictionary) -> void:
	var fdagri_balance: float = user_data.walletData.farmerCreditTokenBalance.to_float()
	var dagri_balance: float = user_data.walletData.dagriBalance.to_float()
	%FDAGRIBalance.text = six_digit_balance_format(fdagri_balance) + " FDAGRI AVAILABLE"
	%DAGRIBalance.text = six_digit_balance_format(dagri_balance) + " DAGRI"
	
	
func _on_get_stake_info_complete(stake_info: Dictionary) -> void:
	%SubmitStakeButton.disabled = false
	%ClaimStakeButton.disabled = false
	
	%RewardReceiveAmount.text = stake_info.rewardAmountFormattedAccrued
	%StakedAmount.text = stake_info.stakeAmountFormatted
	%ReleaseRate.text = "Every " + stake_info.releaseTimeFrame.timeUnitFormatted
	
	
func six_digit_balance_format(balance: float) -> String:
	if balance == 0.0:
		return "0"
	return String.num(balance, 6)


func _on_stake_amount_text_changed(value: String) -> void:
	# Get reference to the StakeAmount LineEdit
	var stake_amount_input: LineEdit = %StakeAmount
	
	# Store current cursor position
	var cursor_pos: int = stake_amount_input.caret_column
	
	# Filter the string to only allow numbers, decimal point, and handle edge cases
	var filtered_text: String = ""
	var has_decimal: bool = false
	
	for i: int in range(value.length()):
		var character: String = value[i]
		
		# Allow digits
		if character.is_valid_int():
			filtered_text += character
		# Allow only one decimal point
		elif character == "." and not has_decimal:
			has_decimal = true
			filtered_text += character
	
	# Prevent starting with decimal point
	if filtered_text.begins_with("."):
		filtered_text = "0" + filtered_text
	
	# Prevent multiple leading zeros (except for "0.")
	if filtered_text.length() > 1 and filtered_text.begins_with("0") and not filtered_text.begins_with("0."):
		filtered_text = filtered_text.lstrip("0")
		if filtered_text == "":
			filtered_text = "0"
	
	# Update the text if it was changed by filtering
	if value != filtered_text:
		stake_amount_input.text = filtered_text
		# Restore cursor position, but don't exceed text length
		stake_amount_input.caret_column = min(cursor_pos, filtered_text.length())


func _on_submit_stake_button_pressed() -> void:
	# Get the stake amount from the input field
	var stake_amount: String = %StakeAmount.text.strip_edges()
	if stake_amount > %FDAGRIBalance.text:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Insufficient FDAGRI balance for staking")
			
		return
	
	# Validate the input
	if stake_amount == "" or stake_amount == "0" or stake_amount == "0.0":
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Invalid stake amount: empty or zero")
		return
	
	# Validate that it's a valid number
	if not stake_amount.is_valid_float():
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Invalid stake amount: not a valid number")
		return
	
	# Convert to float to check if it's positive
	var amount_float: float = stake_amount.to_float()
	if amount_float <= 0.0:
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Invalid stake amount: must be positive")
		return
	
	# Call the staking API
	Staking.stake_tokens(stake_amount)


func _on_stake_tokens_complete(result: Dictionary) -> void:
	# Handle the result of the staking operation
	if result.has("error"):
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Staking failed: " + str(result.error))
	else:
		# Clear the input field on success
		%StakeAmount.text = ""
		# Refresh the stake info to show updated data
		Staking.get_stake_info()
		for main: Control in get_tree().get_nodes_in_group(&"MainMenu"):
			main.message_box("Staking successful!")


func _on_claim_stake_button_pressed() -> void:
	Staking.claim_rewards()
	
	
func _on_visibility_changed() -> void:
	if visible:
		Staking.get_stake_info()
		Auth.auto_login_user()
	else:
		%SubmitStakeButton.disabled = true
		%ClaimStakeButton.disabled = true
