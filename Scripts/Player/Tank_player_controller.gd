extends Node
class_name Tank_player_controller

@onready var tank_rigid: Tank_Rigid = $Tank_Player
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/HUD_Player/Icon
@onready var HUD_aim: Sprite2D = $HUD/HUD_Player/Icon2
@onready var HUD_dir: Sprite3D = $Tank_Player/Forward
@onready var HUD_height_line: Line2D = $HUD/HUD_Player/Height_Line


@onready var HUD_AP: RichTextLabel = $HUD/HUD_Player/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Player/HUD_Score
@onready var HUD_Velocimeter: RichTextLabel = $HUD/HUD_Player/HUD_Velocimeter
@onready var HUD_Objectives: RichTextLabel = $HUD/HUD_Player/HUD_Objectives

@onready var HUD_AP_Bar: ProgressBar = $HUD/HUD_Player/HUD_AP_Bar

@onready var HUD_Death_Screen: Control = $HUD/Death_Screen
@onready var HUD_Victory_Screen: Control = $HUD/Victory

@onready var HUD_Shoot_Ready: TextureProgressBar = $HUD/HUD_Player/Icon2/HUD_Shoot_Ready

@onready var HUD_Map: Map_Visualization = $HUD/HUD_Player/Map

@onready var pause_menu: Pause_menu = $Pause_menu

@export var color: Color = Color.GREEN

@export var max_armor_points: int = 120

var mission_finished = false
var is_destroyed = false

var aim_point_scale_ref: float = 7.5
var aim_point_original_scale: Vector2 = Vector2.ONE



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	tank_rigid.add_to_group("Player")
	
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	tank_rigid.velocimeter.connect(update_Velocimeter)
	tank_rigid.ap_percent.connect(update_AP_Bar)
	
	HUD_Death_Screen.visible = false
	HUD_Victory_Screen.visible = false
	HUD_Map.visible = false
	
	tank_rigid.shoot_recharge.connect(shoot_ready)
	
	#tank_rigid.max_armor_points = max_armor_points
	#tank_rigid.armor_points = max_armor_points
	
	update_HUD()
	
	tank_camera.player = tank_rigid
	
	aim_point_original_scale = HUD_aim.scale
	
	#await get_tree().physics_frame
	#Node.print_orphan_nodes()
	
	pause_menu.game_state.connect(show_HUD)
	pause_menu.color_change.connect(change_HUD_color)
	pause_menu.set_color(color)
	#change_HUD_color(color)
	pass # Replace with function body.


func color_HUD() -> void:
		HUD_aim.modulate = color
		HUD_mouse.modulate = color
		HUD_Score.modulate = color
		HUD_AP.modulate = color
		HUD_Velocimeter.modulate = color
		HUD_Objectives.modulate = color
		HUD_AP_Bar.modulate = color
		HUD_height_line.modulate = color
	

func shoot_ready(charge: float) -> void:
	HUD_Shoot_Ready.value = charge

func _physics_process(delta: float) -> void:
	tank_camera.move_cam(tank_rigid.position, delta)
	#tank_rigid.allign_with_floor(delta)
	
	if pause_menu.visible:
		return
	
	#print(tank_camera.get_mouse_3d_pos())
	HUD_mouse.position = get_viewport().get_mouse_position()
	
	var aim_point = tank_rigid.get_aim_point_3d(tank_rigid.tank_turret.global_position.distance_to(tank_camera.get_mouse_3d_pos()))
	
	var height_ground_pos = aim_point
	height_ground_pos.y = tank_rigid.global_position.y
	
	#print(tank_camera.global_position.y - (aim_point.y))
	
	var aim_new_scale = (aim_point_scale_ref / (tank_camera.global_position.y - (aim_point.y))) * aim_point_original_scale
	
	HUD_aim.scale = aim_new_scale
	
	#print(tank_rigid.get_aim_point_3d())
	HUD_aim.position = tank_camera.unproject_position(tank_rigid.get_aim_point_3d(tank_rigid.tank_turret.global_position.distance_to(tank_camera.get_mouse_3d_pos())))
	#HUD_aim.position = tank_rigid.get_aim_point(get_viewport().get_mouse_position())
	
	HUD_height_line.points = [tank_camera.unproject_position(height_ground_pos),HUD_aim.position]
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if pause_menu.visible:
		return
	
	if is_destroyed:
		if Input.is_action_just_pressed("Shoot"):
			get_tree().reload_current_scene()
		return
	
	if mission_finished:
		if Input.is_action_just_pressed("Shoot"):
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		return
	
	if Input.is_action_just_pressed("Reload"):
		get_tree().reload_current_scene()
		return
	
	var input_dir := Input.get_vector("Left","Right","Forward","Backward")
	
	#print(get_viewport().get_mouse_position())
	
	if Input.is_action_just_pressed("Shoot"):
		tank_rigid.shoot()
	
	tank_rigid.move(input_dir, delta)
	
	#tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	tank_rigid.rotate_turret_to_point_3d(tank_camera.get_mouse_3d_pos())
	
	
	if Input.is_action_just_pressed("Map"):
		HUD_Map.visible = not HUD_Map.visible

func update_HUD() -> void:
	update_AP(tank_rigid.armor_points)
	update_Score(tank_rigid.score)

func update_AP(ap: int) -> void:
	HUD_AP.text = (str(ap) +" AP")
	
	if ap <= 0:
		destruction()

func change_HUD_color(c: Color) -> void:
	color = c
	color_HUD()

func update_Score(score: int) -> void:
	HUD_Score.text = ("Score: "+str(score))

func update_Velocimeter(velocity: float) -> void:
	var final_vel = "%.2f" % (velocity * 5)
	HUD_Velocimeter.text = (final_vel+" Km/h")

func update_Objectives(objectives: String) -> void:
	HUD_Objectives.text = objectives

func update_AP_Bar(percent: float) -> void:
	HUD_AP_Bar.value = percent

func show_HUD(state: bool) -> void:
	
	if is_destroyed or mission_finished:
		state = false
	
	HUD_aim.visible = state
	HUD_mouse.visible = state
	HUD_Score.visible = state
	HUD_AP.visible = state
	HUD_Velocimeter.visible = state
	HUD_Objectives.visible = state
	HUD_AP_Bar.visible = state
	HUD_height_line.visible = state
	HUD_Map.visible = false

func destruction() -> void:
		is_destroyed = true
		
		show_HUD(false)
		
		HUD_Death_Screen.visible = true
		
		return

func finish_mission(result: bool) -> void:
		mission_finished = true
		
		show_HUD(false)
		
		if result:
			
			HUD_Victory_Screen.visible = true
			return
		
		destruction()
		return
	
