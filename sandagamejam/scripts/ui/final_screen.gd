extends Control

@export var leaderboard_internal_name: String

@onready var anim = $AnimationPlayer
@onready var bg = $Background
@onready var message = $Message
@onready var message_label = $Message/Label
@onready var score_panel = $ScorePanel
@onready var newton = $Newton
@onready var score_container = $ScoreContainer
@onready var score_label = $ScoreContainer/Score
@onready var name_label = $ScoreContainer/Name
@onready var ranking_container = $RankingContainer
@onready var play_again_btn = $BtnPlayAgain
@onready var recipe_texture = $Recipe
@onready var loading_label = $LoadingLabel

# Loading text animation
@export var dot_speed: float = 0.5 # Time in seconds to add/remove a dot
@export var max_dots: int = 3

var current_dots: int = 0
var base_text: String = "Loading" # TO DO REPLACE BY LANGUAGE
var timer: Timer

# Preloads de texturas
@onready var bg_win   = preload("res://assets/backgrounds/good_score_bg.png")
@onready var bg_fail  = preload("res://assets/backgrounds/bad_score_bg.png")
@onready var newton_fail = preload("res://assets/sprites/newtown/newton_sad.png")
@onready var newton_win = preload("res://assets/sprites/newtown/newton_happy.png")
@onready var recipe_fail = preload("res://assets/pastry/recipes/recipe_003_wrong.png")
@onready var recipe_win = preload("res://assets/pastry/recipes/recipe_003.png")
@onready var ranking_label_settings: LabelSettings = preload("res://custom_resources/Ranking.tres")

var add_new_score: bool = false
var name_entered: bool = false
var score: int = 100
var max_name_length: int = 6
var current_name: Array = []
var cached_entries: Array = []
var ranking: Array = []
var menu_labels = GlobalManager.menu_labels[GlobalManager.game_language]
var settings_instance = preload("res://custom_resources/Ranking.tres").duplicate()

func _ready():
	AudioManager.play_end_music()
	if GlobalManager.satisfied_customers.size() == 0:
		score = 0
	else:
		score = (round(GlobalManager.time_left) * 10) + (GlobalManager.lives * 100)
	
	settings_instance.font_size = 50
	message_label.label_settings = settings_instance

	score_label.text = menu_labels["ranking"]["score"] + " " + str(score)
	add_new_score = await is_player_in_ranking(score)
	show_name_label()
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and add_new_score:
		#a-z y A-Z
		if (event.unicode >= 65 and event.unicode <=90) or (event.unicode >= 97 and event.unicode <= 122):
			var char_typed = char(event.unicode).to_upper()
			if current_name.size() < max_name_length:
				current_name.append(char_typed)
				show_name_label()
			# Luego del enter
		elif event.keycode == KEY_BACKSPACE and current_name.size() > 0:
				current_name.pop_back()
				show_name_label()
			# Borrar letra
		elif event.keycode == KEY_ENTER and current_name.size() > 0 and not name_entered:
			hide_player_score_labels()
			animate_loading_label()
			await store_in_talo("".join(current_name), score)
			show_ranking()
			name_entered = true
	
# state puede ser: "win", "lose", "timeup"
func show_final_screen(state: GlobalManager.GameState):
	AudioManager.stop_game_music()
	score_panel.visible = false
	recipe_texture.texture = recipe_fail

	match state:
		GlobalManager.GameState.TIMEUP:
			bg.texture = bg_fail
			newton.texture = newton_fail
			message_label.text = menu_labels["final_screen"]["time_up"]
			AudioManager.play_time_up_sfx()
		GlobalManager.GameState.WIN:
			bg.texture = bg_win
			recipe_texture.texture = recipe_win
			newton.texture = newton_win
			message_label.text = menu_labels["final_screen"]["win"]
			AudioManager.play_win_sfx()
		GlobalManager.GameState.GAMEOVER:
			bg.texture = bg_fail
			newton.texture = newton_fail
			message_label.text = menu_labels["final_screen"]["game_over"]
			AudioManager.play_game_over_sfx()
	
	anim.play("final_sequence")
	
func show_name_label():
	var display = ""
	
	if not add_new_score:
		name_label.text = display
		return
	
	for i in range(max_name_length):
		if i < current_name.size():
			display += current_name[i] + ""
		else:
			display += "_ "
	name_label.text =  menu_labels["ranking"]["name"] + "\n" + display 
	
# Animar el "Loading..."
func animate_loading_label():
	loading_label.visible = true # TO DO ANIMATE LOADING LABEL
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = dot_speed
	timer.autostart = true
	timer.timeout.connect(update_dots)
	update_dots()

func update_dots():
	current_dots = (current_dots + 1) % (max_dots + 1)
	loading_label.text = base_text + ".".repeat(current_dots)
	
# Talo Calls
func store_in_talo(username: String, score_value: int) -> void:
	await Talo.players.identify("username", username)
	#var res :=
	await Talo.leaderboards.add_entry(leaderboard_internal_name, score_value)
	_build_entries()

func load_entries_from_talo() -> void:
	var page = 0
	var done = false

	while !done:
		var options := Talo.leaderboards.GetEntriesOptions.new()
		options.page = page
		var res := await Talo.leaderboards.get_entries(leaderboard_internal_name, options)

		# show entries!
		var entries: Array[TaloLeaderboardEntry] = res.entries
		
		#var count: int = res.count
		var is_last_page: bool = res.is_last_page
		if is_last_page:
			done = true
		else:
			page += 1
	
	_build_entries()

# Evaluar si el score entra al ranking
func is_player_in_ranking(score: int) -> bool:
	await load_entries_from_talo()
	var last_child_idx = cached_entries.size()
	var lower_score =  cached_entries[last_child_idx-1].score
	
	return score > lower_score
	
# Muestra el ranking
func show_ranking():
	loading_label.visible = false
	
	var label = play_again_btn.get_node("Label")
	label.text = menu_labels["play_again"] 
	ranking_container.visible = true
	#play_again_btn.visible = true
	
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "final_sequence":
		score_panel.visible = true
		score_panel.modulate.a = 0
		score_panel.create_tween().tween_property(score_panel, "modulate:a", 1.0, 0.4)

func _on_btn_play_again_pressed() -> void:
	queue_free()
	AudioManager.play_click_sfx()
	GameController.reset_game()
	
func _build_entries() -> void:
	free_container_children()
	
	# Get cached entries, recently stored
	cached_entries = Talo.leaderboards.get_cached_entries(leaderboard_internal_name)
	if cached_entries.size() > 10:
		cached_entries = cached_entries.slice(0, 10)
	
	for entry in cached_entries:
		_create_entry(entry)
	
func _create_entry(entry: TaloLeaderboardEntry) -> void:
	# Crear un label por cada item en ranking
	var player_label = Label.new()
	player_label.text = str(entry.position)+". " + entry.player_alias.identifier +" - " + str(int(entry.score))
	player_label.label_settings = ranking_label_settings
	ranking_container.add_child(player_label)
	
# helpers
func free_container_children():
	for child in ranking_container.get_children():
		child.queue_free() 

func hide_player_score_labels():
	message.visible = false
	score_container.visible = false
	
# Replaced by Talo
#func store_in_ranking(username: String, score_value: int):
	#ranking.append({"name": username, "score": score_value})
	## Ordenar de mayor a menor score
	#ranking.sort_custom(func(a, b): return b.score - a.score)
	#if ranking.size() > 10:
		#ranking = ranking.slice(0, 10)
