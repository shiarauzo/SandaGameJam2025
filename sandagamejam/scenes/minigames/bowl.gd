extends Area2D

signal ingredient_captured(ingredient_id: String)

@export var min_x: float = 100
@export var max_x: float = 700
@export var fixed_y: float = 600

func _ready():
	position.y = fixed_y
	collision_layer = 4
	collision_mask = 2
	connect("body_entered", Callable(self, "_on_body_entered"))
	

func _process(delta):

	if Input.is_action_pressed("ui_left"):
		position.x -= 300 * delta
	elif Input.is_action_pressed("ui_right"):
		position.x += 300 * delta

	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_x = get_viewport().get_mouse_position().x
		position.x = clamp(mouse_x, min_x, max_x)

	position.x = clamp(position.x, min_x, max_x)
	position.y = fixed_y
	

func _on_body_entered(body):
	print(" Detecté colisión con:", body.name)

	if not body.has_meta("food_type"):
		return

	var ingredient_id = body.get_meta("food_type")
	var recipe_ingredients = GlobalManager.selected_recipe_data["ingredients"]

	if ingredient_id in recipe_ingredients:
		print("Ingrediente correcto:", ingredient_id)
		emit_signal("ingredient_captured", ingredient_id)
		AudioManager.play_collect_ingredient_sfx()
		GlobalManager.collected_ingredients.append(ingredient_id)
	else:
		print("Ingrediente incorrecto:", ingredient_id)
		AudioManager.play_wrong_ingredient_sfx() 
	if ingredient_id in recipe_ingredients:
		flash_color(Color(0,1,0))
	else:
		flash_color(Color(1,0,0))


	body.queue_free()
func flash_color(color: Color, duration := 0.2):
	if not has_node("Bowl"): return
	var sprite = get_node("Bowl") as Sprite2D
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", color, duration)
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)
