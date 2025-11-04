extends Control

@onready var btn_jugar : Area2D = $Jugar
@onready var btn_creditos : Area2D = $Creditos
@onready var btn_opciones : Area2D = $Opciones
@onready var btn_salir : TextureButton = $Salir

var intro_game = preload("res://scenes/menus/intro.tscn")

func _ready():
	set_button_labels()
	var cursor_texture = preload("res://assets/ui/hand_point.png")
	Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))
	
	# Conectar al cambio de idioma
	if GlobalManager.has_signal("language_changed"):
		GlobalManager.language_changed.connect(_on_language_changed)

func set_button_labels() -> void:	
	var file := FileAccess.open("res://i18n/menu_labels.json", FileAccess.READ)
	if file:
		var json_text := file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_text)
		if data == null:
			push_error("Error al parsear el JSON de menu labels.")
			return
		
		var lang : String = GlobalManager.game_language
		if data.has(lang):
			var labels = data[lang]
			btn_jugar.get_node("CollisionPolygon2D/Label").text = labels["jugar"]
			btn_opciones.get_node("CollisionPolygon2D/Label").text = labels["opciones"]
			btn_creditos.get_node("CollisionPolygon2D/Label").text = labels["creditos"]
		else:
			push_error("Idioma no encontrado en JSON: " + lang)
	else:
		push_error("No se pudo abrir el archivo JSON.")

func _on_language_changed() -> void:
	set_button_labels()

# --------------------
# BOTONES
# --------------------
func _on_jugar_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.play_click_sfx()
		GameController.free_children(GameController.current_scene_container)
		var intro_path = "res://scenes/menus/intro.tscn"
		GameController.load_level(intro_path)

func _on_creditos_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.play_click_sfx()
		var credits_modal = preload("res://scenes/menus/Credits.tscn").instantiate()
		add_child(credits_modal)

func _on_opciones_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		AudioManager.play_click_sfx()
		var opciones_modal = preload("res://scenes/OpcionesModal.tscn").instantiate()
		add_child(opciones_modal)

func _on_salir_pressed() :
	get_tree().quit()

func _on_button_mouse_entered():
	var hand_cursor = preload("res://assets/ui/hand_point.png")
	Input.set_custom_mouse_cursor(hand_cursor, Input.CURSOR_ARROW, Vector2(8, 8))
