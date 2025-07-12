extends Control




func _ready() -> void:
	connect_signals()


func connect_signals() -> void:
	set_bottom_menu_buttons()
	
	
func set_bottom_menu_buttons() -> void:
	for button: TextureButton in get_tree().get_nodes_in_group(&"BottonMenuButtons"):
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		var _1: int = button.pressed.connect(on_set_button_menu_buttons_pressed.bind(button.name))
		var _2: int = button.pressed.connect(on_toggle_container_visibility.bind(button.name))
	
	
func on_set_button_menu_buttons_pressed(button_name: String) -> void:
	for button: TextureButton in get_tree().get_nodes_in_group(&"BottonMenuButtons"):
		var panel: Panel = button.get_parent()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon: TextureRect = button.get_child(0)
		var is_selected: bool = button.name == button_name

		button.button_pressed = is_selected

		# Mutate the existing stylebox (assumes per-panel instance)
		var stylebox: StyleBoxFlat = panel.get_theme_stylebox("panel")
		if is_selected:
			stylebox.bg_color = Color("9ff300")
			icon.modulate = Color("ffffff")
		else:
			stylebox.bg_color = Color("1d1d1d")
			icon.modulate = Color("a2a0a0")
	
			
func on_toggle_container_visibility(button_name: String) -> void:
	var target_name: String = button_name + "Container"
	var current_visible: VBoxContainer = null
	var target_container: VBoxContainer = null

	# Find currently visible container and the target container
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"MainContainers"):
		if container.visible:
			current_visible = container
		if container.name == target_name:
			target_container = container

	# If target not found, do nothing
	if target_container == null:
		return

	# Prepare all others (hide, fade-out)
	for container: VBoxContainer in get_tree().get_nodes_in_group(&"MainContainers"):
		if container != target_container:
			container.visible = false
			container.modulate.a = 0.0

	# Show and animate target
	target_container.visible = true
	target_container.modulate.a = 0.0

	var tween: Tween = create_tween()
	var _trans: Tween = tween.set_trans(Tween.TransitionType.TRANS_SINE)
	var _ease: Tween = tween.set_ease(Tween.EaseType.EASE_IN_OUT)

	if current_visible != null and current_visible != target_container:
		var _fade_out: PropertyTweener = tween.tween_property(current_visible, "modulate:a", 0.0, 0.1)
		var _callback: CallbackTweener = tween.tween_callback(Callable(self, "_hide_container").bind(current_visible))

	var _fade_in: PropertyTweener = tween.tween_property(target_container, "modulate:a", 1.0, 0.25)

	# Reset scroll position
	%SmoothScrollContainer.scroll_vertical = 0

	
	
func _on_home_container_forecast_button_pressed() -> void:
	%WeatherForecastContainer.visible = true
	on_toggle_container_visibility("WeatherForecast")
	on_set_button_menu_buttons_pressed("WeatherForecast")
	
func _on_farms_container_on_farm_card_button_pressed(_farm_id: String) -> void:
	on_toggle_container_visibility("FarmProfile")
	on_set_button_menu_buttons_pressed("FarmProfile")
	
	
func message_box(message: String) -> void:
	%ErrorLabel.text = message
	%AnimationPlayer.play(&"error_message")


func _on_notification_button_pressed() -> void:
	var tween: Tween = create_tween()
	var _1: Tween = tween.set_trans(Tween.TRANS_QUAD)
	var _2: Tween = tween.set_ease(Tween.EASE_OUT)

	if %NotificationsContainer.visible:
		# Animate fade-out and slide-up
		var _3: PropertyTweener = tween.tween_property(%NotificationsContainer, "modulate:a", 0.0, 0.25)
		var _4: PropertyTweener = tween.tween_property(%NotificationsContainer, "position:y", %NotificationsContainer.position.y - 20, 0.25)
		var _5: CallbackTweener = tween.tween_callback(Callable(_hide_notifications_container))


	else:
		# Reset visibility and position before animating in
		%NotificationsContainer.visible = true
		%NotificationsContainer.modulate.a = 0.0
		%NotificationsContainer.position.y += 20  # slide-down start
		var _6: PropertyTweener = tween.tween_property(%NotificationsContainer, "modulate:a", 1.0, 0.25)
		var _7: PropertyTweener = tween.tween_property(%NotificationsContainer, "position:y", %NotificationsContainer.position.y - 20, 0.25)

	
func _hide_notifications_container() -> void:
	%NotificationsContainer.visible = false
