#UILayer
#HUD + manager de mensajes y botones
extends CanvasLayer

@onready var game_hud : Control = null
@onready var message_texture : TextureRect = null
@onready var pause_btn = $PauseBtn
@export var pause_texture: Texture
@export var play_texture: Texture
@onready var timer_label: Label = $GameHUD/HUDContainer/TimerLabel
#Enciclopedia -> TODO: cambiar a una escena independiente
@onready var encyclopedia_ui = $EncyclopediaUI
@onready var tools_btn = $ToolsBtn
@onready var tab_container = $EncyclopediaUI/Panel/TabContainer
@onready var ingredients_box = $EncyclopediaUI/Panel/TabContainer/IngredientsTab/MarginContainer/VBoxContainer
@onready var characters_box = $EncyclopediaUI/Panel/TabContainer/CharactersTab/MarginContainer/VBoxContainer
var font = load("res://assets/fonts/Macondo/Macondo-Regular.ttf")

var typing_speed := 0.01
var characters_data = null

func _ready() -> void:
	self.layer = 0
	game_hud = $GameHUD
	message_texture = $GameHUD/MessageTexture

	if game_hud:
		game_hud.visible = false
	else:
		# Esperar al frame siguiente si aún no existe
		call_deferred("_ready")
	
	if timer_label:
		timer_label.add_theme_color_override("font_color", Color("#a79e91"))
		timer_label.add_theme_color_override("font_outline_color", Color("#19211f"))
		timer_label.add_theme_constant_override("outline_size", 10)
		
	GlobalManager.connect("lives_changed", Callable(self, "_on_lives_changed"))
	GlobalManager.connect("time_changed", Callable(self, "_on_time_changed"))
	GlobalManager.connect("time_up", Callable(self, "_on_hide_ui"))
	GlobalManager.connect("game_over", Callable(self, "_on_hide_ui"))
	GlobalManager.connect("win", Callable(self, "_on_hide_ui"))
	
	if GameController.has_signal("ingredients_minigame_finished"):
		GameController.connect("ingredients_minigame_finished", Callable(self, "_on_ingredients_minigame_exit"))
	
	# Characters
	characters_data = FileHelper.read_data_from_file("res://i18n/characters_moods.json")["characters"]

	populate_list(
		characters_box,
		characters_data,
		"res://assets/sprites/customers/%s_happy.png",
		Vector2(250, 250),
		Vector2(250, 250), # sprite_min_size
		Vector2(500, 0)    # text_min_size
	)

	# Ingredients
	var all_ingredients = []
	all_ingredients += GlobalManager.all_ingredients
	all_ingredients += GlobalManager.fake_ingredients
	all_ingredients += GlobalManager.gravitational_ingredients

	populate_list(
		ingredients_box,
		all_ingredients,
		"res://assets/pastry/ingredients/%s.png",
		Vector2(250, 120),
		Vector2(250, 120), # sprite_min_size
		Vector2(400, 0)    # text_min_size
	)


func show_hud():
	visible = true
	if not game_hud:
		return

	game_hud.visible = true
	_on_lives_changed(GlobalManager.lives, GlobalManager.max_lives)
	_on_time_changed(GlobalManager.time_left)

func show_message(msg_to_display: String = "..."):
	if not message_texture:
		return
	message_texture.visible = true
	var rich_text = message_texture.get_node("RichTextLabel")
	var btn_help = message_texture.get_node("BtnHelp")
	btn_help.visible = false

	rich_text.text = ""
	rich_text.visible = true
	
	# Iniciar coroutine de tipeo
	await start_typing(msg_to_display, rich_text)
	
	show_help_button(btn_help)

func hide_message():
	message_texture.visible = true

func show_help_button(btn: TextureButton):
	var label = btn.get_node("Label")
	label.text = GlobalManager.btn_help_customer_label
	btn.visible = true
	
func _on_lives_changed(new_lives, max_lives):
	game_hud.update_hud(new_lives, max_lives)

func _on_time_changed(new_time):
	game_hud.update_timer(new_time)

func start_typing(msg: String, rich_text: RichTextLabel) -> void:
	var full_text = msg
	rich_text.text = ""
	
	for i in full_text.length():
		rich_text.text += full_text[i]
		await get_tree().create_timer(typing_speed).timeout

# Invertir colores del timer_label
func invest_label_colors():
	if timer_label:
		var font_color = timer_label.get_theme_color("font_color", "Label")
		var outline_color = timer_label.get_theme_color("font_outline_color", "Label")

		timer_label.add_theme_color_override("font_color", outline_color)
		timer_label.add_theme_color_override("font_outline_color", font_color)
		timer_label.add_theme_constant_override("outline_size", 6)

func reset_timer_colors():
	if timer_label:
		timer_label.add_theme_color_override("font_color", Color("#a79e91"))
		timer_label.add_theme_color_override("font_outline_color", Color("#19211f"))
		timer_label.add_theme_constant_override("outline_size", 10)

# Ayudar al cliente
func _on_btn_help_pressed() -> void:
	AudioManager.play_click_sfx()
	AudioManager.stop_customer_sfx()
	AudioManager.play_newton_humming_sfx()
	message_texture.visible = false
	invest_label_colors()
	
	if GameController and not GlobalManager.is_minigame_overlay_visible:
		GameController.show_minigame("res://scenes/minigames/MinigameOverlay.tscn")

func _on_pause_btn_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = false
		pause_btn.texture_normal = pause_texture
	else:
		get_tree().paused = true
		pause_btn.texture_normal = play_texture
	
func _on_hide_ui():
	visible = false

func _on_ingredients_minigame_exit() -> void:
	invest_label_colors()
	
# Funciones para la enciclopedia:
func _on_tools_btn_pressed() -> void:
	encyclopedia_ui.visible = true
	get_tree().paused = true

func _on_close_btn_pressed() -> void:
	encyclopedia_ui.visible = false
	get_tree().paused = false

func populate_list(
	box: VBoxContainer,
	data: Array,
	sprite_path_format: String,
	sprite_size: Vector2,
	sprite_min_size: Vector2 = Vector2(100, 100),
	text_min_size: Vector2 = Vector2(400, 0)
) -> void:
	# Limpia primero
	for child in box.get_children():
		child.queue_free()

	var lang = GlobalManager.game_language

	for entry in data:
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.custom_minimum_size = Vector2(0, sprite_size.y) #Vector2(0, 120)

		# Imagen
		var img_container = Control.new()
		img_container.custom_minimum_size = sprite_size
		img_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		img_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var sprite_path = sprite_path_format % entry["id"]		
		var tex = load(sprite_path)
		
		# Usado en mac
		#if not FileAccess.file_exists(sprite_path):
		#	push_warning("Sprite not found: %s" % sprite_path)
		if tex == null:
			push_warning("Could not load: %s" % sprite_path)
		else:
			var tex_rect = TextureRect.new()
			tex_rect.texture = tex
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.custom_minimum_size = sprite_min_size
			tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			img_container.add_child(tex_rect)
		hbox.add_child(img_container)

		# Textos
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		# Nombre
		var name_label = Label.new()
		name_label.text = entry["name"].get(lang, entry["id"])
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.custom_minimum_size = text_min_size
		text_vbox.add_child(name_label)
		
		# Descripción
		if "specialty" in entry:
			var desc_label = Label.new()
			desc_label.text = entry["specialty"].get(lang, entry["id"])
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.custom_minimum_size = text_min_size
			text_vbox.add_child(desc_label)
			
		# Descripción
		if "description" in entry:
			var desc_label = Label.new()
			desc_label.text = entry["description"].get(lang, entry["id"])
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.custom_minimum_size = text_min_size
			text_vbox.add_child(desc_label)

		hbox.add_child(text_vbox)
		box.add_child(hbox)

	apply_font_to_labels(box, font, 24)

func apply_font_to_labels(node: Node, label_font: FontFile, size: int = 16) -> void:
	for child in node.get_children():
		if child is Label:
			child.add_theme_font_override("font", label_font)
			child.add_theme_font_size_override("font_size", size)
		elif child.get_child_count() > 0:
			# Aplicar también a hijos dentro de sub-contenedores
			apply_font_to_labels(child, label_font, size)
