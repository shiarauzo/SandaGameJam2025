# customer.gd
extends Node2D

signal arrived_at_center(customer : Node2D)
signal listen_customer_pressed
	
@onready var sprite : Sprite2D = $Sprite2D
@onready var btn_listen : TextureButton = $BtnListen
@onready var sfx_entering : AudioStreamPlayer = $SFXEntering
@export var speed: float = 300.0

const BASE_VIEWPORT = Vector2(1152, 648)
const BASE_START_X = -200
const BASE_OFFSET_Y = 80
const BASE_OFFSET_X = 100
const SPRITE_POSITION_Y = 414
const SPRITE_POSITION_X = 1152.0/2.0 + -80

var target_y_ratio := 0.05
var relative_x: float = 0.5
var customer_scale: float = 0.165 #escala de referencia
var character_id: String
var mood_id: String
var texts: Dictionary
var language: String

var state = GlobalManager.State.ENTERING
	
func _ready():
	pass
	
# Setup: Preparar, reinicializar data del cliente
func setup(data: Dictionary, lang: String):
	await ready
	character_id = data["character_id"]
	mood_id = data["mood_id"]
	texts = data["texts"]
	language = lang
	# Buscar el botón de forma segura (sin depender de @onready aún)
	btn_listen.visible = false

# Desde CafeLevel1 se llama a:
func move_to(target_position: Vector2) -> void:
	sfx_entering.play()
	
	var dist := (target_position - position).length()
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, dist / speed)
	
	# Cuando termine el tween (cliente en el centro) → emitir señal
	tween.finished.connect(customer_positioned)

func customer_positioned():
	sfx_entering.stop()
	set_state(GlobalManager.State.SEATED)
	
	var label = btn_listen.get_node("Label")
	label.text = GlobalManager.btn_listen_customer_label
	btn_listen.visible = true
	
	emit_signal("arrived_at_center", self)

func set_state(new_state: GlobalManager.State):
	state = new_state
	match state:
		GlobalManager.State.ENTERING:
			var path := "res://assets/sprites/customers/%s_entering.png" % character_id
			var alt_path := "res://assets/sprites/customers/adalovelace_entering.png"
			load_customer_texture(path, alt_path)
		GlobalManager.State.SEATED:
			var path := "res://assets/sprites/customers/%s_%s.png" % [character_id, mood_id]
			var alt_path := "res://assets/sprites/customers/adalovelace_sleepy.png"
			load_customer_texture(path, alt_path)
		GlobalManager.State.FAIL:
			var path := "res://assets/sprites/customers/%s_%s_fail.png" % [character_id, mood_id]
			var alt_path := "res://assets/sprites/customers/%s_%s.png" % [character_id, mood_id]
			load_customer_texture(path, alt_path)
		GlobalManager.State.SUCCESS:
			var path := "res://assets/sprites/customers/%s_happy.png" % character_id
			var alt_path := "res://assets/sprites/customers/adalovelace_happy.png"
			load_customer_texture(path, alt_path)

	if sprite.texture:
		position_listen_button()

# Colocar el botón justo arriba del sprite
func position_listen_button():
	if sprite and sprite.texture:
		var texture_size = get_sprite_size()
		var btn_size = btn_listen.size
		
		# centrar en X, arriba en Y
		var x = -btn_size.x / 2
		var y = -texture_size.y/2 - btn_size.y - 10
		
		btn_listen.position = Vector2(x, y)

#Cargar sprite y aplicar escala.
func get_sprite_size() -> Vector2:
	if sprite.texture:
		return sprite.texture.get_size() * sprite.scale
	return Vector2.ZERO

func get_initial_position() -> Vector2:
	return Vector2(BASE_START_X, SPRITE_POSITION_Y)

func get_target_position() -> Vector2:
	return Vector2(SPRITE_POSITION_X, SPRITE_POSITION_Y)
	
# Cambios de estados:
func react_angry():
	AudioManager.play_customer_sfx(GlobalManager.current_customer.genre, GlobalManager.current_customer.mood_id, true)
	set_state(GlobalManager.State.FAIL)
	GlobalManager.return_customer()

func react_happy():
	AudioManager.play_customer_sfx(GlobalManager.current_customer.genre, "happy", true)
	set_state(GlobalManager.State.SUCCESS)
	GlobalManager.mark_customer_as_satisfied()
	
func _on_btn_listen_pressed() -> void:
	AudioManager.play_click_sfx()
	if GlobalManager.current_customer.is_empty():
		print("⚠️ No hay cliente actual")
		return
		
	AudioManager.play_customer_sfx(GlobalManager.current_customer.genre, GlobalManager.current_customer.mood_id)
	emit_signal("listen_customer_pressed")

# Helper
func load_customer_texture(path: String, alt_path: String):
	var tex : Texture2D = null
			
	if ResourceLoader.exists(path, "Texture2D"):
		tex = load(path)
	else:
		tex = load(alt_path)
		
	sprite.texture = tex
	
func hide_listen_button():
	btn_listen.visible = false
	
# Obtener factor uniforme para la escala
func get_scale_factor():
	var viewport_size: Vector2 = get_viewport().size
	var scale_factor = min(viewport_size.x / BASE_VIEWPORT.x, viewport_size.y / BASE_VIEWPORT.y)
	
	return scale_factor
