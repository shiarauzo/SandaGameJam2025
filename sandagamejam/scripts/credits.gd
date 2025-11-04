extends Control

@onready var credits_theme: Theme = preload("res://custom_resources/Credits.tres")
@onready var members_box: VBoxContainer = $ScrollContainer/VBoxContainer/MemberBox
@onready var roles_box: VBoxContainer = $ScrollContainer/VBoxContainer/RolesBox
@onready var thanks_box: VBoxContainer = $ScrollContainer/VBoxContainer/ThanksBox
@onready var team_name_label: Label = $ScrollContainer/VBoxContainer/TeamName

var TEAM_NAME_SIZE = 42
var SECTION_LABEL_TITLE_SIZE = 26
var SUBTITLE_SIZE = 32
var MEMBER_NAME_SIZE = 30
var MEMBER_LINK_SIZE = 24
var VERTICAL_SPACER = 16

var credits_data = {}
var general_data = {}

func _ready():
	self.theme = credits_theme
	load_credits_data()
	populate_credits()

func load_credits_data():
	credits_data = FileHelper.read_data_from_file("res://i18n/credits.json")
	general_data = credits_data["general"]
	credits_data = credits_data[GlobalManager.game_language]
	

func populate_credits():
	# --- Team name --- #
	team_name_label.text = general_data.get("team_name", "Team Name")
	team_name_label.add_theme_font_size_override("font_size", TEAM_NAME_SIZE)
	team_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# --- Members --- #
	var members_arr = general_data.get("members", [])
	if members_arr.size() > 0:
		var text = credits_data.get("labels").get("members")
		var members_title = set_section_label_title(text)
		members_box.add_child(members_title)
	
		for i in range(members_arr.size()):
			var member = members_arr[i]
			var member_vbox = VBoxContainer.new()
			member_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			if i < members_arr.size() - 1:
				member_vbox.add_theme_constant_override("separation", 4)
			var name_text = member.get("name", "")
			var name_label = set_centered_text_with_size(name_text, MEMBER_NAME_SIZE)
			member_vbox.add_child(name_label)
			
			# Redes sociales
			var socials_arr = member.get("socials", [])
			if socials_arr.size() > 0:
				for social in socials_arr:
					var social_box = set_social_link_box(social)
					member_vbox.add_child(social_box)
			
			members_box.add_child(member_vbox)
			create_spacers(i, members_arr, members_box)
	
	# Separador Members → Roles
	members_box.add_child(create_section_separator())
	
	 # --- Roles --- #
	var roles_arr = general_data.get("roles", [])
	if roles_arr.size() > 0:
		var text = credits_data.get("roles_section_title", "Roles")
		var roles_title = set_section_label_title(text)
		roles_box.add_child(roles_title)
		
		for i in range(roles_arr.size()):
			var role = roles_arr[i]
			var role_key = role.get("key", "")
			var role_title = credits_data["roles_titles"].get(role_key, "Role")
			var role_label = set_centered_text_with_size(role_title, SUBTITLE_SIZE)
			roles_box.add_child(role_label)
			
			var people_arr = role.get("people", [])
			if people_arr.size() > 0:
				var translated_people = []
				for person in people_arr:
					if person == "all_team":
						translated_people.append(credits_data["labels"].get("all_team", "All team"))
					else:
						translated_people.append(person)
				
				var people_text = ", ".join(translated_people)
				var people_label = set_centered_text_with_size(people_text, MEMBER_NAME_SIZE)
				roles_box.add_child(people_label)
			
			# Spacer entre roles
			create_spacers(i, roles_arr, roles_box)

	# Separador Roles →  Special Thanks
	roles_box.add_child(create_section_separator())
	
	# --- Special Thanks --- #
	var special_thanks = credits_data.get("special_thanks", {})
	if special_thanks.size() > 0:
		var text = credits_data.get("labels").get("special_thanks")
		var thanks_title = set_section_label_title(text)
		thanks_box.add_child(thanks_title)

		for key in special_thanks.keys():
			var section = special_thanks[key]
			var thanks_text = section.get("text", key)
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			
			# Texto descriptivo
			var text_label = set_centered_text_with_size(thanks_text, MEMBER_NAME_SIZE)
			vbox.add_child(text_label)
			
			# Revisar si tiene authors con URLs
			var authors_arr = section.get("authors", [])
			for author in authors_arr:
				var url = author.get("url", "")
				var type_icon = "soundcloud"
				var social_box = set_social_link_box({"type": type_icon, "url": url})
				vbox.add_child(social_box)
			
			thanks_box.add_child(vbox)
	
	# Special Thanks →   External Resources
	thanks_box.add_child(create_section_separator())
		
	# --- External Resources --- #
	var resources = credits_data.get("resources", [])
	if resources.size() > 0:
		var text = credits_data.get("labels").get("resources", "External Resources")
		var resources_title = set_section_label_title(text)
		thanks_box.add_child(resources_title)

		for i in range(resources.size()):
			var resource = resources[i]
			var resource_text = resource.get("text", "")
			if resource_text != "":
				var resource_label = set_centered_text_with_size(resource_text, MEMBER_LINK_SIZE)
				thanks_box.add_child(resource_label)
			# Spacer entre resources
			create_spacers(i, resources, thanks_box)

func set_section_label_title(text: String):
	var title = Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", SECTION_LABEL_TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	return title;

func set_social_link_box(social: Dictionary):
	var icon_type = social.get("type", "")
	var icon_path = "res://assets/icons/" + icon_type + ".svg"
	var url = social.get("url", "")
	var parts = url.rsplit("/", false, 1)
	var username = parts[1] if parts.size() > 1 else url
	
	# Contenedor horizontal para icono + label
	var social_box = HBoxContainer.new()
	social_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Botón con icono
	var btn = TextureButton.new()
	btn.texture_normal = load(icon_path)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(24, 24)
	btn.connect("pressed", func():
		OS.shell_open(url)
	)
	social_box.add_child(btn)
	
	# Texto clickeable estilo Label
	var user_label = Label.new()
	user_label.text = username
	user_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	user_label.theme = credits_theme
	user_label.mouse_filter = Control.MOUSE_FILTER_STOP
	user_label.size_flags_vertical = Control.SIZE_FILL
	
	# Guardar color original
	var base_color = user_label.get_theme_color("font_color", "Label")
	# Setear el color base explícitamente
	user_label.add_theme_color_override("font_color", base_color)
	# Hover → aclarar un poco
	user_label.mouse_entered.connect(func():
		user_label.add_theme_color_override("font_color", base_color.lightened(0.2))
	)

	# Al salir, volver exactamente al base_color
	user_label.mouse_exited.connect(func():
		user_label.add_theme_color_override("font_color", base_color)
	)

	# Click
	user_label.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			OS.shell_open(url)
	)

	# Contenedor del ícono + texto
	social_box.add_child(user_label)
	
	return social_box
	
func set_centered_text_with_size(text: String, custom_size: int):
	var new_label = Label.new()
	new_label.text = text
	new_label.add_theme_font_size_override("font_size", custom_size)
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	return new_label

func create_spacers(i: int, items_arr: Array, box_to_add: VBoxContainer):
	if i < items_arr.size() - 1:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, VERTICAL_SPACER)
		box_to_add.add_child(spacer)

func create_section_separator() -> Control:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Spacer arriba
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, VERTICAL_SPACER)
	vbox.add_child(top_spacer)
	
	# Label central con - * -
	var separator_label = Label.new()
	separator_label.text = "~ * ~"
	separator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	separator_label.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	vbox.add_child(separator_label)
	
	# Spacer abajo
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, VERTICAL_SPACER)
	vbox.add_child(bottom_spacer)
	
	return vbox

func debug_last_child_box(box: VBoxContainer):
	if box.get_child_count() == 0:
		return
	var marker = ColorRect.new()
	marker.color = Color.RED
	marker.custom_minimum_size = Vector2(0, 4)
	# Añadir justo debajo del último hijo
	box.add_child(marker)

func _on_close_button_pressed() -> void:
	AudioManager.play_click_sfx()
	queue_free()
