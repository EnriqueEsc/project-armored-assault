extends Menu

@onready var main_menu_window: Control = $Main_menu_buttons
@onready var mission_list_button: Button = $Main_menu_buttons/Buttons/Mission_list
@onready var settings_button: Button = $Main_menu_buttons/Buttons/Settings
@onready var quit_game_button: Button = $Main_menu_buttons/Buttons/Quit_game

@onready var mission_list_window: Control = $Mission_list
@onready var mission_buttons_grid: GridContainer = $Mission_list/Buttons/Mission_selection_container/Mission_button_container
@onready var back_to_main_menu: Button = $Mission_list/Buttons/Back

@onready var briefing_window: Control = $Mission_Briefing
@onready var briefing_text: Typing_Text = $Mission_Briefing/Briefing_text
@onready var to_tank_selection: Button = $Mission_Briefing/Tank_selection
@onready var back_to_mission_list: Button = $Mission_Briefing/Back

@onready var tank_selection_window: Control = $Tank_selection_menu
@onready var tank_buttons_grid: GridContainer = $Tank_selection_menu/Tank_selection_container/Tank_button_container
@onready var attachment_selection_text: RichTextLabel = $Tank_selection_menu/Buttons/Attachment_text
@onready var attachment_selection: OptionButton = $Tank_selection_menu/Buttons/Attachment_selection
@onready var tank_info_text: RichTextLabel = $Tank_selection_menu/Tank_info
@onready var tank_preview_rect: TextureRect = $Tank_selection_menu/Preview_Rect
@onready var tank_selection_back: Button = $Tank_selection_menu/Buttons/Back
@onready var start_mission_button: Button = $Tank_selection_menu/Buttons/Start_mission

@onready var credits_button: Button = $Main_menu_buttons/Buttons/Credits
@onready var credits_window: Control = $Credits
@onready var credits_back_button: Button = $Credits/Buttons/Back


@onready var settings_window: Control = $Settings_Menu
@onready var fullscreen_button: CheckButton = $Settings_Menu/Video/Cont/Cont/Fullscreen/FullscreenButton

@onready var aim_3d_button: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/Aim3D/Aim3DButton
@onready var aim_guideline_button: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/AimGuideline/AimGuidelineButton
@onready var aim_limited_button: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/AimLimited/AimLimitedButton
@onready var third_person_button: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/ThirdPerson/ThirdPersonButton
@onready var use_csg_button: CheckButton = $Settings_Menu/Video/Cont/Cont/UseCSG/UseCSGButton
@onready var see_trough: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/SeeTrough/SeeTroughButton
@onready var max_effects_text: RichTextLabel = $Settings_Menu/Video/Cont/Cont/MaxParticleEffects/MaxParticleEffectsText
@onready var max_effects_bar: HScrollBar = $Settings_Menu/Video/Cont/Cont/MaxParticleEffects/MaxParticleSlider
@onready var mouse_visible_button: CheckButton = $Settings_Menu/Video/Cont/Cont/MouseVisible/MouseVisibleButton


@onready var destruction_effects_text: RichTextLabel = $Settings_Menu/Video/Cont/Cont/DestructionEffects/DestructionEffectsText
@onready var destruction_effects_option: OptionButton = $Settings_Menu/Video/Cont/Cont/DestructionEffects/DestructionEffectsSelection

@onready var aim_assist_text: RichTextLabel = $Settings_Menu/Gameplay/Cont/Cont/AimAssistType/AimAssistTypeText
@onready var aim_assist_option: OptionButton = $Settings_Menu/Gameplay/Cont/Cont/AimAssistType/AimAssistTypeSelection

@onready var enable_emmisions_button: CheckButton = $Settings_Menu/Video/Cont/Cont/EnableEmmision/EnableEmmisionButton

@onready var use_controller: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/UseController/UseControllerButton
@onready var use_controller_vibration: CheckButton = $Settings_Menu/Gameplay/Cont/Cont/ControllerVibration/ControllerVibrationButton

@onready var move_type_text: RichTextLabel = $Settings_Menu/Gameplay/Cont/Cont/MovementType/MovementTypeText
@onready var move_type_option: OptionButton = $Settings_Menu/Gameplay/Cont/Cont/MovementType/MovementTypeSelection

@onready var enable_vsync_button: CheckButton = $Settings_Menu/Video/Cont/Cont/EnableVsync/EnableVsyncButton

@onready var flamable_mode_selection: OptionButton = $Settings_Menu/Gameplay/Cont/Cont/FlamableMode/FlamableModeSelection
@onready var max_active_fire_text: RichTextLabel = $Settings_Menu/Gameplay/Cont/Cont/MaxActiveFire/MaxActiveFireText
@onready var max_active_fire_bar: HScrollBar = $Settings_Menu/Gameplay/Cont/Cont/MaxActiveFire/MaxActiveFireSlider
@onready var odds_fire_exp_text: RichTextLabel = $Settings_Menu/Gameplay/Cont/Cont/OddsFireOnExplosion/OddsFireOnExplosionText
@onready var odds_fire_exp_bar: HScrollBar = $Settings_Menu/Gameplay/Cont/Cont/OddsFireOnExplosion/OddsFireOnExplosionSlider

@onready var folliage_density_text: RichTextLabel = $Settings_Menu/Video/Cont/Cont/FolliageDensity/FolliageDensityText
@onready var folliage_density_bar: HScrollBar = $Settings_Menu/Video/Cont/Cont/FolliageDensity/FolliageDensitySlider
@onready var animated_shaders_button: CheckButton = $Settings_Menu/Video/Cont/Cont/AnimatedShaders/AnimatedShadersButton

@onready var save_settings_button: Button = $Settings_Menu/Buttons/Save
@onready var settings_back: Button = $Settings_Menu/Buttons/Back


var selected_mission: Mission_Data = null
var selected_tank: Tank_Data = null
var selected_attachment: Attachment = null

var tanks_preview_models: Array[Node3D] = []

@onready var tank_point: Node3D = $Tank_Preview/SubViewport/Point

var attachments: Array[Attachment] = []

@onready var settigns_panels: Array[Control] = [$Settings_Menu/Video,$Settings_Menu/Gameplay]

@onready var video_settings_button: Button = $Settings_Menu/Buttons/Video
@onready var gameplay_settings_button: Button = $Settings_Menu/Buttons/Gameplay

func _set_buttons() -> void:
	#mission_list_button.button_down.connect(show_briefing)
	mission_list_button.button_down.connect(switch_active.bind(mission_list_window))
	settings_button.button_down.connect(switch_active.bind(settings_window))
	settings_button.button_down.connect(update_settings_window)
	quit_game_button.button_down.connect(get_tree().quit)
	
	credits_button.button_down.connect(switch_active.bind(credits_window))
	credits_back_button.button_down.connect(switch_active.bind(credits_window))
	
	#load_mission_button.button_down.connect(select_mission.bind("res://Scenes/test_mission.tscn"))

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
	
	max_active_fire_bar.value_changed.connect(update_max_active_fire_text)
	odds_fire_exp_bar.value_changed.connect(update_odds_fire_exp_text)
	folliage_density_bar.value_changed.connect(update_folliage_density_text)
	
	settings_button.button_down.connect(activate_settings_panel.bind(0))
	video_settings_button.button_down.connect(activate_settings_panel.bind(0))
	gameplay_settings_button.button_down.connect(activate_settings_panel.bind(1))
	
	
	mission_list_window.visible = false
	briefing_window.visible = false
	tank_selection_window.visible = false
	settings_window.visible = false
	credits_window.visible = false
	
	briefing_text.set_process(true)
	
	for i in 10:
		await get_tree().process_frame
	
	create_move_options()
	create_destruction_effects_options()
	create_aim_assist_options()
	
	create_tank_selection_buttons()
	create_mission_selection_buttons()
	create_attachments_options()
	
	create_flamable_modes_options()


func activate_settings_panel(i: int) -> void:
	if i < 0 or i > settigns_panels.size():
		return
	for x in range(settigns_panels.size()):
		if x != i:
			settigns_panels[x].visible = false
			continue
		settigns_panels[x].visible = true


func load_scene() -> void:
	if selected_mission != null:
		Settings_Manager.INSTANCE.current_tank_used_in_game = selected_tank
		Save_File_Manager.INSTANCE.current_mission = selected_mission
		Save_File_Manager.INSTANCE.current_attachment = selected_attachment
		get_tree().change_scene_to_file("res://Scenes/Missions/"+selected_mission.mission_file_path_name+".tscn")

func select_mission(mission: Mission_Data) -> void:
	selected_mission = mission

func switch_active(window: Control) -> void:
	window.visible = not window.visible

func create_move_options() -> void:
	var skating: String = Tank_player_controller.Move_Types.keys()[Tank_player_controller.Move_Types.Skating]
	
	for m in Tank_player_controller.Move_Types:
		if m == skating:
			continue
		move_type_option.add_item(m)
		
func create_destruction_effects_options() -> void:
	for m in Settings_Manager.INSTANCE.Destruction_Effects_Mode:
		destruction_effects_option.add_item(m)

func create_aim_assist_options() -> void:
	for a in Settings_Manager.INSTANCE.Aim_Assist_Type:
		aim_assist_option.add_item(a)


func update_settings_window() -> void:
	fullscreen_button.button_pressed = Settings_Manager.INSTANCE.fullscreen
	aim_3d_button.button_pressed = Settings_Manager.INSTANCE.aim_3d
	aim_guideline_button.button_pressed = Settings_Manager.INSTANCE.aim_guideline
	aim_limited_button.button_pressed = Settings_Manager.INSTANCE.aim_limited
	third_person_button.button_pressed = Settings_Manager.INSTANCE.third_person
	use_csg_button.button_pressed = Settings_Manager.INSTANCE.use_csg
	see_trough.button_pressed = Settings_Manager.INSTANCE.see_trough_buildings
	max_effects_bar.value = Settings_Manager.INSTANCE.max_effects
	update_max_effects_text(max_effects_bar.value)
	
	#enable_mouse_assist_button.button_pressed = Settings_Manager.INSTANCE.enable_mouse_assist
	aim_assist_option.selected = Settings_Manager.INSTANCE.aim_assist_type
	
	enable_emmisions_button.button_pressed = Settings_Manager.INSTANCE.enable_emmisions
	
	destruction_effects_option.selected = Settings_Manager.INSTANCE.destruction_effects_mode
	
	mouse_visible_button.button_pressed = Settings_Manager.INSTANCE.mouse_visible
	
	use_controller.button_pressed = Settings_Manager.INSTANCE.controller_aim
	move_type_option.selected = Settings_Manager.INSTANCE.move_type
	use_controller_vibration.button_pressed = Settings_Manager.INSTANCE.use_vibration 
	
	enable_vsync_button.button_pressed = Settings_Manager.INSTANCE.vsync_enabled
	
	flamable_mode_selection.selected = Settings_Manager.INSTANCE.flamable_mode
	
	max_active_fire_bar.value = Settings_Manager.INSTANCE.max_active_fire
	update_max_active_fire_text(max_active_fire_bar.value)
	
	odds_fire_exp_bar.value = Settings_Manager.INSTANCE.odds_start_fire_on_explosion
	update_odds_fire_exp_text(odds_fire_exp_bar.value)
	
	folliage_density_bar.value = Settings_Manager.INSTANCE.folliage_density
	update_folliage_density_text(folliage_density_bar.value)
	
	animated_shaders_button.button_pressed = Settings_Manager.INSTANCE.use_animated_shaders

func check_mission_can_start() -> void:
	start_mission_button.visible = selected_mission != null and selected_tank

func show_briefing(text: String) -> void:
	briefing_window.visible = true
	briefing_text.set_text_to_type(text)
	briefing_text.show_skip_text(true)



func load_attachments() -> void:
	attachments.clear()
	var dir = DirAccess.open("res://Prefabs/Attachments")
	
	if dir:
		#print("ola Missione")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tscn") or file_name.ends_with(".remap"):
					var clean_name = file_name.trim_suffix(".remap")
					var path = "res://Prefabs/Attachments".path_join(clean_name)
					var attachment = load(path) as PackedScene
					attachment = attachment.instantiate() as Attachment
					if attachment:
						#print("olasi ",file_name)
						attachments.append(attachment)
			file_name = dir.get_next()
		dir.list_dir_end()
		#load_unlocked_missions()

func create_attachments_options() -> void:
	load_attachments()
	attachment_selection.add_item("None")
	for a in attachments:
		attachment_selection.add_item(a.attachment_name)
	attachment_selection.item_selected.connect(select_attachment)

func select_attachment(i: int) -> void:
	if i > attachments.size():
		return
	if i == 0:
		selected_attachment = null
		print(null)
		return
	i -= 1
	selected_attachment = attachments[i]
	print(attachments[i])

func create_mission_selection_buttons() -> void:
	#var missions: Array = get_missions("res://Scenes/Missions/")
	var missions: Array[Mission_Data] = Save_File_Manager.INSTANCE.all_missions
	
	missions.reverse()
	
	for t in missions:
		
		var mission_button = Button.new()
		mission_button.text = t.mission_name
		mission_button.custom_minimum_size = Vector2(200,50)
		mission_buttons_grid.add_child(mission_button)
		mission_button.button_down.connect(select_mission.bind(t))
		mission_button.button_down.connect(show_briefing.bind(t.briefing))

func get_missions(path: String) -> Array:
	var missions: Array = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var mis = dir.get_next()
		
		while mis != "":
			if not dir.current_is_dir() or (mis != "." and mis != ".."):
				mis = mis.split(".tscn")[0]
				missions.append(mis)
			mis = dir.get_next()
			
		dir.list_dir_end()
		
	return missions


func create_tank_selection_buttons() -> void:
	var tanks: Array = Save_File_Manager.INSTANCE.tanks_unlocked
	
	for t in tanks:
		print(t.tank_Name)
		var tank_button = Button.new()
		tank_button.text = t.tank_Name
		tank_button.custom_minimum_size = Vector2(200,50)
		$Tank_selection_menu/Tank_selection_container/Tank_button_container.add_child(tank_button)
		tank_button.button_down.connect(select_tank.bind(t))
		
		var tank_p = null
		#print(t.filename)
		
		if ResourceLoader.exists("res://Prefabs/Player/"+t.filename+".tscn"):
			print("COÑO ",t.filename)
			tank_p = load("res://Prefabs/Player/"+t.filename+".tscn")
		
		if not tank_p:
			print("COÑO ",t.filename)
			tank_p = load("res://Prefabs/Player/tank.tscn")
		
		if tank_p:
			var tank_clone = tank_p.instantiate() as Tank_Rigid
			tank_clone.static_model = true
			tank_clone.set_process(false)
			tank_clone.set_physics_process(false)
			for tu in tank_clone.vehicle_turrets:
				tu.static_model = true
				tu.set_process(false)
				tu.set_physics_process(false)
				tu.rotation.y = 0
			tank_point.add_child(tank_clone)
			tanks_preview_models.append(tank_clone)
			tank_button.button_down.connect(show_tank.bind(tank_clone))
	
	show_tank(null)

func restart_tank_selection() -> void:
	selected_tank = null
	tank_info_text.text = ""
	tank_preview_rect.visible = false
	show_tank(null)
	attachment_selection.selected = 0
	attachment_selection.visible = false
	attachment_selection_text.visible = false

func select_tank(tank: Tank_Data) -> void:
	selected_tank = tank
	print(tank.tank_Name)
	show_tank_info()
	check_mission_can_start()
	attachment_selection.visible = true
	attachment_selection_text.visible = true

func show_tank(tank: Tank_Rigid) -> void:
	for t in tanks_preview_models:
		t.visible = false
	if tank:
		tank.visible = true

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
	
	tank_preview_rect.visible = true

func update_max_effects_text(i: int) -> void:
	max_effects_text.text = "Max particle effects ("+str(i)+")"
	
func update_max_active_fire_text(i: int) -> void:
	max_active_fire_text.text = "Max concurrent fire ("+str(i)+")"
	
func update_odds_fire_exp_text(i: int) -> void:
	odds_fire_exp_text.text = "Odds of start fire on explosion ("+str(i)+")%"
	
func update_folliage_density_text(i: int) -> void:
	folliage_density_text.text = "Folliage density ("+str(i)+")%"

func create_flamable_modes_options() -> void:
	for a in Settings_Manager.INSTANCE.FlamableModes:
		flamable_mode_selection.add_item(a)


func save_settings() -> void:
	Settings_Manager.INSTANCE.fullscreen = fullscreen_button.button_pressed
	Settings_Manager.INSTANCE.aim_3d = aim_3d_button.button_pressed
	Settings_Manager.INSTANCE.aim_guideline = aim_guideline_button.button_pressed
	Settings_Manager.INSTANCE.aim_limited = aim_limited_button.button_pressed
	Settings_Manager.INSTANCE.third_person = third_person_button.button_pressed
	Settings_Manager.INSTANCE.use_csg = use_csg_button.button_pressed
	Settings_Manager.INSTANCE.see_trough_buildings = see_trough.button_pressed
	Settings_Manager.INSTANCE.max_effects = max_effects_bar.value
	
	Settings_Manager.INSTANCE.destruction_effects_mode = destruction_effects_option.selected
	
	#Settings_Manager.INSTANCE.enable_mouse_assist = enable_mouse_assist_button.button_pressed
	
	Settings_Manager.INSTANCE.aim_assist_type = aim_assist_option.selected
	
	Settings_Manager.INSTANCE.enable_emmisions = enable_emmisions_button.button_pressed
	
	Settings_Manager.INSTANCE.mouse_visible = mouse_visible_button.button_pressed
	
	Settings_Manager.INSTANCE.controller_aim = use_controller.button_pressed
	Settings_Manager.INSTANCE.move_type = move_type_option.selected
	Settings_Manager.INSTANCE.use_vibration = use_controller_vibration.button_pressed
	
	Settings_Manager.INSTANCE.vsync_enabled = enable_vsync_button.button_pressed
	
	Settings_Manager.INSTANCE.flamable_mode = flamable_mode_selection.selected
	
	Settings_Manager.INSTANCE.max_active_fire = max_active_fire_bar.value
	Settings_Manager.INSTANCE.odds_start_fire_on_explosion = odds_fire_exp_bar.value
	Settings_Manager.INSTANCE.folliage_density = folliage_density_bar.value
	
	Settings_Manager.INSTANCE.use_animated_shaders = animated_shaders_button.button_pressed
	
	Settings_Manager.INSTANCE.save_settings()
