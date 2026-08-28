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
@onready var load_demo_button: Button = $"Mission_Briefing/Run demo"
@onready var back_to_mission_list: Button = $Mission_Briefing/Back


@onready var settings_window: Control = $Settings_Menu
@onready var fullscreen_button: CheckButton = $Settings_Menu/Buttons/Fullscreen
@onready var save_settings_button: Button = $Settings_Menu/Buttons/Save
@onready var settings_back: Button = $Settings_Menu/Buttons/Back


var selected_mission: String = ""


	

func _set_buttons() -> void:
	#mission_list_button.button_down.connect(show_briefing)
	mission_list_button.button_down.connect(switch_active.bind(mission_list_window))
	settings_button.button_down.connect(switch_active.bind(settings_window))
	settings_button.button_down.connect(update_settings_window)
	quit_game_button.button_down.connect(get_tree().quit)
	
	
	load_mission_button.button_down.connect(select_mission.bind("res://Scenes/test_mission.tscn"))
	load_mission_button.button_down.connect(show_briefing)
	back_to_main_menu.button_down.connect(switch_active.bind(mission_list_window))
	
	load_demo_button.button_down.connect(load_scene)
	back_to_mission_list.button_down.connect(switch_active.bind(briefing_window))
	back_to_mission_list.button_down.connect(briefing_text.break_typing)
	
	update_settings_window()
	
	#fullscreen_button.button_down.connect(set_fullscreen)
	save_settings_button.button_down.connect(save_settings)
	settings_back.button_down.connect(switch_active.bind(settings_window))
	
	mission_list_window.visible = false
	briefing_window.visible = false
	settings_window.visible = false

func load_scene() -> void:
	if selected_mission != "":
		get_tree().change_scene_to_file(selected_mission)

func select_mission(mission: String) -> void:
	selected_mission = mission

func switch_active(window: Control) -> void:
	window.visible = not window.visible

func update_settings_window() -> void:
	fullscreen_button.button_pressed = Settings_Manager.INSTANCE.fullscreen

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


func save_settings() -> void:
	Settings_Manager.INSTANCE.fullscreen = fullscreen_button.button_pressed
	Settings_Manager.INSTANCE.save_settings()
