extends Control

func _ready() -> void:
	connect_signals()

func connect_signals() -> void:
	var _1: int = Auth.session_check_complete.connect(_on_session_check_complete)
	var _timer: int = get_tree().create_timer(5.0).timeout.connect(_on_timer_timeout)
	
	
func _on_timer_timeout() -> void:
	Auth.auto_login_user()
	
	
func _on_session_check_complete(session: Dictionary) -> void:
	if session.is_empty():
		change_to_auth_scene()
		return
	
	if session.has("error"):
		change_to_auth_scene()
	elif session.has("walletAddress"):
		change_to_main_menu_scene()
	
	
func change_to_auth_scene() -> void:
	var scene: PackedScene = ResourceLoader.load("res://Scenes/auth_screen.tscn")
	var _1: int = get_tree().change_scene_to_packed(scene)
	
	
func change_to_main_menu_scene() -> void:
	var scene: PackedScene = ResourceLoader.load("res://Scenes/main_menu.tscn")
	var _1: int = get_tree().change_scene_to_packed(scene)
