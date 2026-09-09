extends Menu

@onready var main_menu_window: Control = $Main_menu_buttons
@onready var mission_list_button: Button = $Main_menu_buttons/Buttons/Mission_list
@onready var settings_button: Button = $Main_menu_buttons/Buttons/Settings
@onready var quit_game_button: Button = $Main_menu_buttons/Buttons/Quit_game

@onready var mission_list_window: Control = $Mission_list
@onready var load_mission_button: Button = $Mission_list/Buttons/Load_mission
@onready var back_to_main_menu: Button = $Mission_list/Buttons/Back

@onready var briefing_window: Control = $Mission_Briefing
@onready var briefing_text: Typing_Text = $Mission_Briefing/Briefing_text
@onready var to_tank_selection: Button = $Mission_Briefing/Tank_selection
@onready var back_to_mission_list: Button = $Mission_Briefing/Back

@onready var tank_selection_window: Control = $Tank_selection_menu
@onready var tank_buttons_grid: GridContainer = $Tank_selection_menu/Tank_selection_container/Tank_button_container
@onready var tank_info_text: RichTextLabel = $Tank_selection_menu/Tank_info
@onready var tank_selection_back: Button = $Tank_selection_menu/Buttons/Back
@onready var start_mission_button: Button = $Tank_selection_menu/Buttons/Start_mission

@onready var settings_window: Control = $Settings_Menu
@onready var fullscreen_button: CheckButton = $Settings_Menu/Buttons/Fullscreen

@onready var aim_3d_button: CheckButton = $"Settings_Menu/Buttons/3D_Aim"
@onready var aim_guideline_button: CheckButton = $Settings_Menu/Buttons/Aim_guideline
@onready var aim_limited_button: CheckButton = $Settings_Menu/Buttons/Aim_limited
@onready var third_person_button: CheckButton = $Settings_Menu/Buttons/Third_person
@onready var max_effects_text: RichTextLabel = $Settings_Menu/Buttons/Max_effects_text
@onready var max_effects_bar: HScrollBar = $Settings_Menu/Buttons/Max_effects_bar

@onready var save_settings_button: Button = $Settings_Menu/Buttons/Save
@onready var settings_back: Button = $Settings_Menu/Buttons/Back


var selected_mission: String = ""
var selected_tank: Tank_Data = null



func _set_buttons() -> void:
	#mission_list_button.button_down.connect(show_briefing)
	mission_list_button.button_down.connect(switch_active.bind(mission_list_window))
	settings_button.button_down.connect(switch_active.bind(settings_window))
	settings_button.button_down.connect(update_settings_window)
	quit_game_button.button_down.connect(get_tree().quit)
	
	load_mission_button.button_down.connect(select_mission.bind("res://Scenes/test_mission.tscn"))
	load_mission_button.button_down.connect(show_briefing)
	back_to_main_menu.button_down.connect(switch_active.bind(mission_list_window))
	
	to_tank_selection.button_down.connect(switch_active.bind(tank_selection_window))
	to_tank_selection.button_down.connect(check_mission_can_start)
	back_to_mission_list.button_down.connect(switch_active.bind(briefing_window))
	back_to_mission_list.button_down.connect(briefing_text.break_typing)
	
	restart_tank_selection()
	tank_selection_back.button_down.connect(switch_active.bind(tank_selection_window))
	tank_selection_back.button_down.connect(restart_tank_selection)
	start_mission_button.button_down.connect(load_scene)
	
	update_settings_window()
	
	#fullscreen_button.button_down.connect(set_fullscreen)
	max_effects_bar.value_changed.connect(update_max_effects_text)
	save_settings_button.button_down.connect(save_settings)
	settings_back.button_down.connect(switch_active.bind(settings_window))
	
	
	create_tank_selection_buttons()
	
	mission_list_window.visible = false
	briefing_window.visible = false
	tank_selection_window.visible = false
	settings_window.visible = false

func load_scene() -> void:
	if selected_mission != "":
		Settings_Manager.INSTANCE.current_tank_used_in_game = selected_tank
		get_tree().change_scene_to_file(selected_mission)

func select_mission(mission: String) -> void:
	selected_mission = mission

func switch_active(window: Control) -> void:
	window.visible = not window.visible

func update_settings_window() -> void:
	fullscreen_button.button_pressed = Settings_Manager.INSTANCE.fullscreen
	aim_3d_button.button_pressed = Settings_Manager.INSTANCE.aim_3d
	aim_guideline_button.button_pressed = Settings_Manager.INSTANCE.aim_guideline
	aim_limited_button.button_pressed = Settings_Manager.INSTANCE.aim_limited
	third_person_button.button_pressed = Settings_Manager.INSTANCE.third_person
	max_effects_bar.value = Settings_Manager.INSTANCE.max_effects
	update_max_effects_text(max_effects_bar.value)

func check_mission_can_start() -> void:
	start_mission_button.visible = selected_mission != "" and selected_tank

func show_briefing() -> void:
	briefing_window.visible = true
	briefing_text.set_text_to_type("....
....
.>>> Message recieved...
.
.[20/12/2029]
.
.We've recieve some intel about a militia's outpost hidden within the coastal ghost town, it's an isolated group, so it's a mission of a sole man, intel says they have tanks tho, so don't be overconfident.
.
.We need you to destroy the outpost, the garrison and spread as much chaos as possible, we need to keep the upper hand on psychological warfare.
.
.Good luck out there.
.
.This are your orders today, pilot.
....
....
....>> Destroy all the tanks on the surrounding area.
....>> Destroy the outpost's structures.
....>> Spread as much chaos as you can.")


func create_tank_selection_buttons() -> void:
	var tanks: Array = []
	var dir = DirAccess.open("res://Data/Tanks")
	
	if dir:
		print("ola tanke")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tres") or file_name.ends_with(".remap"):
					var clean_name = file_name.trim_suffix(".remap")
					var path = "res://Data/Tanks".path_join(clean_name)
					var tank = ResourceLoader.load(path) as Tank_Data
					if tank:
						tanks.append(tank)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	for t in tanks:
		print(t.tank_Name)
		var tank_button = Button.new()
		tank_button.text = t.tank_Name
		tank_button.custom_minimum_size = Vector2(200,50)
		$Tank_selection_menu/Tank_selection_container/Tank_button_container.add_child(tank_button)
		tank_button.button_down.connect(select_tank.bind(t))
		

func restart_tank_selection() -> void:
	selected_tank = null
	tank_info_text.text = ""

func select_tank(tank: Tank_Data) -> void:
	selected_tank = tank
	print(tank.tank_Name)
	show_tank_info()
	check_mission_can_start()

func show_tank_info() -> void:
	var info: String = "[font_size=20]Tank_Data[/font_size]\n\n"
	
	info += "> Armor points: " + str(selected_tank.max_armor_points) + "\n\n"
	info += "> Max speed: " + str(selected_tank.max_speed) + "\n\n"
	info += "> Acceleration: " + str(selected_tank.acceleration) + "\n\n"
	info += "> Steering speed: " + str(selected_tank.turn_speed) + "\n\n"
	info += "> Steering acceleration: " + str(selected_tank.turning_acceleration) + "\n\n"
	#info += "> Friction: " + str(selected_tank.friction) + "\n\n"
	info += "> Traction: " + str(selected_tank.traction) + "\n\n"
	info += "> Firing rate: " + str(selected_tank.fire_rate_prim) + "\n\n"
	
	tank_info_text.text = info

func update_max_effects_text(i: int) -> void:
	max_effects_text.text = "Max particle effects ("+str(i)+")"

func save_settings() -> void:
	Settings_Manager.INSTANCE.fullscreen = fullscreen_button.button_pressed
	Settings_Manager.INSTANCE.aim_3d = aim_3d_button.button_pressed
	Settings_Manager.INSTANCE.aim_guideline = aim_guideline_button.button_pressed
	Settings_Manager.INSTANCE.aim_limited = aim_limited_button.button_pressed
	Settings_Manager.INSTANCE.third_person = third_person_button.button_pressed
	Settings_Manager.INSTANCE.max_effects = max_effects_bar.value
	Settings_Manager.INSTANCE.save_settings()
