extends VBoxContainer

signal forecast_button_pressed
signal report_pest_button_pressed

func _ready() -> void:
	set_greetings_label() 


func _on_weather_card_forecast_button_pressed() -> void:
	forecast_button_pressed.emit()
	
	
func set_greetings_label() -> void:
	var greetings: Array[String] = [
		"Hope your crops are thriving!",
		"Let's grow something amazing today!",
		"Sunshine and success to you!",
		"Plant good seeds, reap great harvests!",
		"The soil is calling — time to shine!",
		"Let the earth reward your hard work!",
		"A perfect day for smart farming!",
		"Nature’s ready — are you?",
		"May your yields be plentiful!",
		"Let’s turn dirt into gold!"
	]
	var random_greeting: String = greetings[randi() % greetings.size()]
	%GreetingsLabel.text = "Hello " + User.username +"!"
	%GreetingQuote.text = random_greeting


func _on_quick_actions_card_report_pest_button_pressed() -> void:
	report_pest_button_pressed.emit()
