# Bowl.gd
extends Area2D

signal ingredient_captured(ingredient_id: String)

@onready var sprite: Sprite2D = $Sprite2D

var min_x: float = 50.0
var max_x: float = 650.0
var fixed_y: float = 500.0
var following_mouse: bool = true

func _ready():
	# NO establecer position.y aquí, se hace desde setup_bowl()
	
	# Configurar collision layers
	collision_layer = 4  # Layer 3 (2^2 = 4)
	collision_mask = 2   # Layer 2 (detecta ingredientes)
	
	connect("area_entered", Callable(self, "_on_area_entered"))
	
	print("🥣 Bowl inicializado")

func _process(_delta: float):
	if following_mouse:
		var mouse_x = get_viewport().get_mouse_position().x
		position.x = clamp(mouse_x, min_x, max_x)
		# Mantener Y fija
		position.y = fixed_y

func _on_area_entered(area: Area2D):
	print("Bowl detectó área:", area.name)
	
	if area.has_meta("food_type"):
		var ingredient_id = area.get_meta("food_type")
		print("  → Es ingrediente:", ingredient_id)
		emit_signal("ingredient_captured", ingredient_id)
		area.queue_free()
	else:
		print("  → No tiene meta 'food_type'")

# Función helper para configuración externa
func setup(min_x_val: float, max_x_val: float, y_pos: float):
	min_x = min_x_val
	max_x = max_x_val
	fixed_y = y_pos
	position.y = fixed_y
	print("🥣 Bowl configurado: min_x=%s, max_x=%s, y=%s" % [min_x, max_x, fixed_y])

# FIN DEL ARCHIVO - No agregar nada más abajo
