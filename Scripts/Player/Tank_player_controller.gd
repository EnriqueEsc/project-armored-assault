extends Node
class_name Tank_player_controller

signal aim_to(point: Vector3)

@onready var tank_rigid: Tank_Rigid = null
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/HUD_Player/Icon
var HUD_aim: Array[Sprite2D] = []
var HUD_Shoot_Ready: Array[TextureProgressBar] = []
var HUD_height_line: Array[Line2D] = []


@onready var HUD_AP: RichTextLabel = $HUD/HUD_Player/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Player/HUD_Score
@onready var HUD_Velocimeter: RichTextLabel = $HUD/HUD_Player/HUD_Velocimeter
@onready var HUD_Objectives: RichTextLabel = $HUD/HUD_Player/HUD_Objectives

@onready var HUD_AP_Bar: ProgressBar = $HUD/HUD_Player/HUD_AP_Bar

@onready var HUD_Boss_info: HUD_Boss_Info = $HUD/HUD_Player/HUD_Boss_Info

@onready var HUD_Death_Screen: Control = $HUD/Death_Screen
@onready var HUD_Victory_Screen: Control = $HUD/Victory


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
	var tank_load
	var tank_data
	if Settings_Manager.INSTANCE.current_tank_used_in_game:
		tank_data = Settings_Manager.INSTANCE.current_tank_used_in_game
		if tank_data.tank_Name != "MK_01 vindicator":
			tank_load = load("res://Prefabs/Player/tank.tscn")
		else:
			tank_load = load("res://Prefabs/Player/endavour.tscn")
	else:
		tank_load = load("res://Prefabs/Player/endavour.tscn")
		tank_data = load("res://Data/Tanks/mk-0_test.tres") as Tank_Data
	
	tank_rigid = tank_load.instantiate() as Tank_Rigid
	
	
	add_child(tank_rigid)
	
	#tank_rigid.global_rotation = Vector3.ZERO
	print(" POSITION TANK ",rad_to_deg(tank_rigid.global_rotation.y))
	
	tank_rigid.tank_Data = tank_data
	tank_rigid.tank_Data._apply_values(tank_rigid)
	
	tank_rigid.add_to_group("Player")
	
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	tank_rigid.velocimeter.connect(update_Velocimeter)
	tank_rigid.ap_percent.connect(update_AP_Bar)
	
	HUD_Death_Screen.visible = false
	HUD_Victory_Screen.visible = false
	HUD_Map.visible = false
	HUD_Boss_info.show_boss_info()
	
	tank_rigid.shoot_recharge.connect(shoot_ready)
	
	#tank_rigid.max_armor_points = max_armor_points
	#tank_rigid.armor_points = max_armor_points
	
	update_HUD()
	
	tank_camera.player = tank_rigid
	
	
	#await get_tree().physics_frame
	#Node.print_orphan_nodes()
	#change_HUD_color(color)
	
	await get_tree().physics_frame
	
	for t in tank_rigid.vehicle_turrets:
		aim_to.connect(t.rotate_turret_to_point_3d)
		var new_aim = Sprite2D.new()
		new_aim.texture = load("res://Sprites/Test/MousePointer.png")
		var new_ready = TextureProgressBar.new()
		new_ready.texture_progress = load("res://Sprites/Test/ShootingPoint.png")
		var new_line = Line2D.new()
		new_line.width = 3
		new_line.points = [Vector2(0,0),Vector2(0,0)]
		
		$HUD/HUD_Player.add_child(new_aim)
		$HUD/HUD_Player.move_child(new_aim,0)
		$HUD/HUD_Player.add_child(new_line)
		$HUD/HUD_Player.move_child(new_line,0)
		new_aim.add_child(new_ready)
		new_aim.scale = Vector2(0.15,0.15)
		new_ready.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		new_ready.scale = Vector2(1.3,1.3)
		new_ready.position = Vector2(-166.667,-166.667)
		
		
		HUD_aim.append(new_aim)
		HUD_Shoot_Ready.append(new_ready)
		HUD_height_line.append(new_line)
		
	
	aim_point_original_scale = HUD_aim[0].scale
	
	pause_menu.game_state.connect(show_HUD)
	pause_menu.color_change.connect(change_HUD_color)
	pause_menu.set_color(color)


func color_HUD() -> void:
		#HUD_aim.modulate = color
		HUD_mouse.modulate = color
		HUD_Score.modulate = color
		HUD_AP.modulate = color
		HUD_Velocimeter.modulate = color
		HUD_Objectives.modulate = color
		HUD_AP_Bar.modulate = color
		HUD_Boss_info.color_boss_info(color)
		
		for l in HUD_height_line:
			l.modulate = color
		
		for a in HUD_aim:
			a.modulate = color
	

func shoot_ready(charge: float) -> void:
	for s in HUD_Shoot_Ready:
		s.value = charge

func _physics_process(delta: float) -> void:
	tank_camera.move_cam(tank_rigid.position, delta)
	#tank_rigid.allign_with_floor(delta)
	
	if pause_menu.visible:
		return
	
	#print(tank_camera.get_mouse_3d_pos())
	HUD_mouse.position = get_viewport().get_mouse_position()
	#HUD_aim.scale = aim_new_scale
	
	#print(tank_rigid.get_aim_point_3d())
	var counter: int = 0
	for a in HUD_aim:
		
		var aim_point = tank_rigid.get_aim_point_3d(counter, tank_rigid.vehicle_turrets[counter].global_position.distance_to(tank_camera.get_mouse_3d_pos()))
		
		var height_ground_pos = aim_point
		height_ground_pos.y = tank_rigid.global_position.y
		
		#print(tank_camera.global_position.y - (aim_point.y))
		
		var aim_new_scale = (aim_point_scale_ref / (tank_camera.global_position.y - (aim_point.y))) * aim_point_original_scale
		HUD_aim[counter].scale = aim_new_scale
		
		HUD_aim[counter].position = tank_camera.unproject_position(tank_rigid.get_aim_point_3d(counter, tank_rigid.vehicle_turrets[counter].global_position.distance_to(tank_camera.get_mouse_3d_pos())))
		HUD_height_line[counter].points = [tank_camera.unproject_position(height_ground_pos),HUD_aim[counter].position]
		counter += 1
	#HUD_aim.position = tank_rigid.get_aim_point(get_viewport().get_mouse_position())
	
	#HUD_height_line.points = [tank_camera.unproject_position(height_ground_pos),HUD_aim.position]
	


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
	
	if Input.is_action_just_pressed("Attachment"):
		tank_rigid.use_attachment()
	
	tank_rigid.move(input_dir, delta)
	
	#tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	#tank_rigid.rotate_turret_to_point_3d(tank_camera.get_mouse_3d_pos())
	aim_to.emit(tank_camera.get_mouse_3d_pos())
	
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
		HUD_Boss_info.update_boss_active(state)
	
	#HUD_aim.visible = state
	HUD_mouse.visible = state
	HUD_Score.visible = state
	HUD_AP.visible = state
	HUD_Velocimeter.visible = state
	HUD_Objectives.visible = state
	HUD_AP_Bar.visible = state
	HUD_Boss_info.show_boss_info()
	#HUD_height_line.visible = state
	HUD_Map.visible = false
	
	for l in HUD_height_line:
		l.visible = state
	
	for a in HUD_aim:
		a.visible = state

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
	
