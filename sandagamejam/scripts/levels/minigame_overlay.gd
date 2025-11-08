
extends Node2D

signal ingredients_minigame_started
signal ingredients_minigame_timeout

@onready var texture_rect: TextureRect = $TextureRect
@onready var menu_container: Control = $TextureRect/MenuContainer
@onready var recipe_container: Control = $TextureRect/RecipeContainer
@onready var btn_prepare: TextureButton = $TextureRect/BtnPrepareRecipe
@onready var bowl: Area2D = $TextureRect/Bowl

var minigame_started := false
var active_tweens := []

func _ready():
	load_menu_data()
	load_btn_labels()
	btn_prepare.anchor_top = 0.0
	btn_prepare.anchor_bottom = 0.0
	btn_prepare.anchor_left = 0.5
	btn_prepare.anchor_right = 0.5
	btn_prepare.position = Vector2(0, 40) 
	print("🎮 MinigameOverlay listo.")


func hide_menu_container():
	menu_container.visible = false

func show_menu_container():
	load_menu_data()
	menu_container.visible = true

func hide_recipe_container():
	recipe_container.visible = false

func show_recipe_container():
	recipe_container.visible = true


func show_selected_recipe(idx: int) -> void:
	GlobalManager.selected_recipe_idx = idx
	load_selected_recipe_data(idx)
	load_ingredients_assets()
	hide_menu_container()
	show_recipe_container()

func load_menu_data() -> void:
	var recipe_buttons = [
		menu_container.get_node("Recipe1"),
		menu_container.get_node("Recipe2"),
		menu_container.get_node("Recipe3"),
		menu_container.get_node("Recipe4")
	]
	
	for i in range(GlobalManager.current_level_recipes.size()):
		var recipe_data = GlobalManager.current_level_recipes[i]
		var recipe_id = recipe_data["id"]
		var path = "res://assets/pastry/recipes/%s.png" % recipe_id
		if not ResourceLoader.exists(path):
			print("No existe asset:", path)
			continue
		
		var tex = load(path)
		if i < recipe_buttons.size():
			var button = recipe_buttons[i]
			var sprite = button.get_node("Sprite2D") 
			if sprite:
				sprite.texture = tex
		
func load_btn_labels() -> void:
	var continue_label = recipe_container.get_node("BtnContinue/Label")
	var back_label = recipe_container.get_node("BtnBack/Label")
	var cook_label = btn_prepare.get_node("Label")
	continue_label.text = GlobalManager.btn_choose_recipe_label
	back_label.text = GlobalManager.btn_reject_recipe_label
	cook_label.text = GlobalManager.btn_cook_recipe_label
	
func load_selected_recipe_data(idx: int) -> void:
	var lang = GlobalManager.game_language
	var recipe_selected = GlobalManager.current_level_recipes[idx]
	var rec_name = recipe_selected["name"][lang]
	var riddle = recipe_selected["riddle"][lang]
	var text = "[center][font_size=35]" + rec_name + "[/font_size][/center]\n\n"
	text += "[font_size=36] " + riddle + "[/font_size]"

	var rich_label_text = recipe_container.get_node("RichTextLabel")
	rich_label_text.bbcode_enabled = true
	rich_label_text.text = text
	
func load_ingredients_assets():
	var recipe_selected = GlobalManager.current_level_recipes[GlobalManager.selected_recipe_idx]
	var ingredients = recipe_selected["ingredients"]

	var ing_container = recipe_container.get_node("IngredientsContainer")
	clear_children(ing_container)

	for i in range(ingredients.size()):
		var ing_id = ingredients[i]
		var wrapper = create_ingredient_wrapper(ing_id, false)
		ing_container.add_child(wrapper)


func start_ingredient_minigame():
	print("🎮 START MINIGAME...")
	emit_signal("ingredients_minigame_started")
	minigame_started = true
	var recipe_selected = GlobalManager.current_level_recipes[GlobalManager.selected_recipe_idx]
	GlobalManager.selected_recipe_data = recipe_selected
	
	var array_size = GlobalManager.ingredientes_array_size
	var ingredients = recipe_selected["ingredients"]
	var ingr_loop = generate_arr(ingredients, array_size)
	animate_ingredients(ingr_loop)
	btn_prepare.visible = true

func animate_ingredients(ingr_loop: Array) -> void:
	print("EMPEZAR A RECOLECTAR INGREDIENTES!!! ", ingr_loop)
	clear_children_except_bowl(texture_rect)

	var start_y := -200  
	var end_y := texture_rect.size.y + 100 
	var x_positions := [150, 250, 350, 450, 550] 
	var duration := 4.0
	var spawn_interval := 1.1

	for i in range(ingr_loop.size()):
		var ing_id = ingr_loop[i]
		var ingredient = create_ingredient_area2d(ing_id)
		texture_rect.add_child(ingredient)

		var x_pos = x_positions[i % x_positions.size()]
		ingredient.position = Vector2(x_pos, start_y)

		var tween := create_tween()
		tween.tween_property(ingredient, "position:y", end_y, duration)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN)\
			.set_delay(spawn_interval * i)
		tween.tween_callback(Callable(ingredient, "queue_free"))
		
		active_tweens.append(tween)
	
		if i == ingr_loop.size() - 1:
			tween.finished.connect(func():
				emit_signal("ingredients_minigame_timeout")
			)

func create_ingredient_area2d(ingredient_id: String) -> Area2D:
	var path = "res://assets/pastry/ingredients/%s.png" % ingredient_id
	if not ResourceLoader.exists(path):
		print("⚠No existe asset:", path)
		return null

	var tex = load(path)
	
	var ingredient = Area2D.new()
	ingredient.name = "Ingredient_" + ingredient_id
	
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(0.35, 0.35)
	ingredient.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = tex.get_size() * 0.35
	collision.shape = shape
	ingredient.add_child(collision)
	
	ingredient.collision_layer = 2
	ingredient.collision_mask = 4
	ingredient.set_meta("food_type", ingredient_id)
	
	return ingredient

func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
		
func clear_children_except_bowl(container: Node) -> void:
	for child in container.get_children():
		if child.name != "Bowl" and child.name != "BtnPrepareRecipe":
			child.queue_free()


func _on_recipe_1_pressed() -> void:
	AudioManager.play_click_sfx()
	show_selected_recipe(0)

func _on_recipe_2_pressed() -> void:
	AudioManager.play_click_sfx()
	show_selected_recipe(1)

func _on_recipe_3_pressed() -> void:
	AudioManager.play_click_sfx()
	show_selected_recipe(2)

func _on_recipe_4_pressed() -> void:
	AudioManager.play_click_sfx()
	show_selected_recipe(3)

func _on_btn_back_pressed() -> void:
	AudioManager.play_click_sfx()
	hide_recipe_container()
	show_menu_container()

func _on_btn_continue_pressed() -> void:
	AudioManager.play_click_sfx()
	hide_recipe_container()
	hide_menu_container()
	start_ingredient_minigame()
	
func _on_btn_prepare_recipe_pressed() -> void:
	AudioManager.play_click_sfx()
	GlobalManager.recipe_started = true
	
	if minigame_started:
		for t in active_tweens:
			if is_instance_valid(t):
				t.kill()
		active_tweens.clear()
		
		clear_children_except_bowl(texture_rect)
		
		minigame_started = false
		btn_prepare.visible = false
		GameController.make_newton_cook()

func _on_ingredient_captured(ingredient_id: String):
	print("Bowl capturó:", ingredient_id)
	GlobalManager.collected_ingredients.append(ingredient_id)
	AudioManager.play_collect_ingredient_sfx()
	
	if GlobalManager.collected_ingredients.size() >= 2:
		btn_prepare.visible = true
		btn_prepare.disabled = false
		

func create_ingredient_wrapper(ingredient_id: String, is_clickable: bool = false):
	var path = "res://assets/pastry/ingredients/%s.png" % ingredient_id
	if not ResourceLoader.exists(path):
		print("No existe asset:", path)
		return null

	var tex = load(path)
	
	var wrapper = Control.new()
	wrapper.custom_minimum_size = tex.get_size() * 0.25
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sprite = TextureRect.new()
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.anchor_right = 1
	sprite.anchor_bottom = 1
	sprite.size_flags_horizontal = Control.SIZE_FILL
	sprite.size_flags_vertical = Control.SIZE_FILL

	wrapper.add_child(sprite)
	return wrapper


func generate_arr(base: Array, base_len: int) -> Array:
	var result = base.duplicate()
	add_random_ingredients(result, GlobalManager.fake_ingredients)
	
	if GlobalManager.lives < GlobalManager.max_lives:
		add_random_ingredients(result, GlobalManager.gravitational_ingredients)
	
	while result.size() < base_len:
		var rand = base[randi() % base.size()]
		result.append(rand)
	
	shuffle_array(result)
	return result

func shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

func add_random_ingredients(result: Array, source_array: Array) -> void:
	var count = 2
	for i in range(count):
		var ing = source_array[randi() % source_array.size()]
		result.append(ing.id)
