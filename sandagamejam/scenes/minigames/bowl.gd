extends Area2D

signal ingredient_captured(ingredient_id: String)

@export var min_x: float = 100
@export var max_x: float = 700
@export var fixed_y: float = 600

func _ready():
	position.y = fixed_y
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta):
	# Movimiento con teclado
	if Input.is_action_pressed("ui_left"):
		position.x -= 300 * delta
	elif Input.is_action_pressed("ui_right"):
		position.x += 300 * delta
	# Movimiento con mouse
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_x = get_viewport().get_mouse_position().x
		position.x = clamp(mouse_x, min_x, max_x)

	position.x = clamp(position.x, min_x, max_x)
	position.y = fixed_y

func _on_body_entered(body):
	if body.has_meta("food_type"):
		var id = body.get_meta("food_type")
		print("🍓 Ingrediente capturado:", id)
		emit_signal("ingredient_captured", id)
		body.queue_free()
