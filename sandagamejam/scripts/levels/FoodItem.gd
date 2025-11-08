extends Area2D

@export var food_type: String = ""   # Ej: "ing_001"
@onready var sprite: Sprite2D = $Sprite2D

func setup(texture: Texture, type: String):
	sprite.texture = texture
	food_type = type

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		print("Seleccionaste ingrediente:", food_type)
		GlobalManager.check_food(food_type)
