extends Control

@onready var credits_theme: Theme = preload("res://custom_resources/Credits.tres")
@onready var scroll: ScrollContainer = ScrollContainer.new()
@onready var grid: GridContainer = GridContainer.new()
@onready var close_button: TextureButton = $UI/close_button  

	
func _ready():
	self.theme = credits_theme
	
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_top = 0.5
	scroll.anchor_bottom = 0.5

	scroll.offset_left = -300
	scroll.offset_top = -150
	scroll.offset_right = 300
	scroll.offset_bottom = 150

	scroll.custom_minimum_size = Vector2(600, 400)

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)


	_add_credit("Melissa Huerta", "Game Developer & Tech Designer")
	_add_credit("Shiara Arauzo", "Game Developer")
	_add_credit("Malu Munayco", "Game Developer")
	_add_credit("Selene Negrón", "Concept Artist & 2D Artist")
	_add_credit("Ariadna Mestanza", "Concept Artist & 2D Artist")
	_add_credit("Fabrizio Murguia", "Game Designer")
	_add_credit("Melissa Huerta", "Game Developer & Tech Designer")
	_add_credit("Shiara Arauzo", "Game Developer")
	_add_credit("Malu Munayco", "Game Developer")
	var btn = $close_button
	print("close_button encontrado? ", btn)
	if btn:
		btn.pressed.connect(_on_close_button_pressed)
	else:
		push_error("No encontré el nodo close_button")




func _add_credit(member: String, role: String):
	var name_label = Label.new()
	name_label.text = member
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var role_label = Label.new()
	role_label.text = role
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	grid.add_child(name_label)
	grid.add_child(role_label)
	
func _on_close_button_pressed() -> void:
	print("⚡ Botón presionado, intentando volver al menú")
	var path = "res://scenes/menus/MainMenu.tscn"
	if ResourceLoader.exists(path):
		var scene = load(path)
		get_tree().change_scene_to_packed(scene)
	else:
		push_error("No se encontró la escena en: " + path)
