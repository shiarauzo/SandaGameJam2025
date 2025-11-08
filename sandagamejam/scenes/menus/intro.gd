extends Node2D

@onready var btn_start: TextureButton = $Comenzar_Game
@onready var text_intro: Label = $TextureRect/text_intro
@onready var btn_back: TextureButton = $Retroceder_Button if has_node("Retroceder_Button") else null

var texts = [
	"¡Bienvenido a mi cafetería! Te preguntarás qué hace Isaac Newton con un mandil y preparando pasteles.",
	"Pues, descubrí mi pasión por la pastelería cuando me cayó una manzana en la cabeza mientras descansaba bajo un manzanero.",
	"Durante los siguientes minutos, llegarán mis mejores clientes para degustar mis preparaciones con mi fruta favorita: la manzana. ¡Es hora de abrir!, aquí viene nuestro primer cliente."
]

var typing_speed := 0.05
var typing_timer: Timer
var full_text := ""
var char_index := 0
var current_index := 0
var is_typing := false

func _ready():
	
	typing_timer = Timer.new()
	typing_timer.wait_time = typing_speed
	typing_timer.one_shot = false
	typing_timer.timeout.connect(_on_typing_timeout)
	add_child(typing_timer)
	
	_show_text(texts[current_index])
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	
	if btn_back:
		btn_back.pressed.connect(_on_btn_back_pressed)
		btn_back.visible = false 

func _show_text(new_text: String):
	full_text = new_text
	char_index = 0
	text_intro.text = ""
	is_typing = true
	typing_timer.start()

func _on_typing_timeout():
	if char_index < full_text.length():
		text_intro.text += full_text[char_index]
		char_index += 1
	else:
		typing_timer.stop()
		is_typing = false

func _on_btn_start_pressed():
	AudioManager.play_click_sfx()

	if is_typing:
		text_intro.text = full_text
		typing_timer.stop()
		is_typing = false
		return

	current_index += 1

	
	if btn_back and current_index > 0:
		btn_back.visible = true

	if current_index < texts.size():
		_show_text(texts[current_index])
	else:
		var level_1_path = "res://scenes/levels/PastryLevel1.tscn"
		GlobalManager.start_game()
		GameController.load_level(level_1_path)
		GameController.show_newton_layer()

func _on_btn_back_pressed():
	AudioManager.play_click_sfx()

	if is_typing:
		text_intro.text = full_text
		typing_timer.stop()
		is_typing = false
		return

	if current_index > 0:
		current_index -= 1
		_show_text(texts[current_index])

	
	if current_index == 0 and btn_back:
		btn_back.visible = false
