extends Node

@onready var tank_rigid: Tank_Rigid = $Tank_Player
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/Icon
@onready var HUD_aim: Sprite2D = $HUD/Icon2
@onready var HUD_dir: Sprite3D = $Tank_Player/Forward
@onready var HUD_height_line: Line2D = $HUD/Height_Line


@onready var HUD_AP: RichTextLabel = $HUD/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Score
@onready var HUD_Velocimeter: RichTextLabel = $HUD/HUD_Velocimeter

@onready var HUD_Death_Screen: Control = $HUD/Death_Screen

@onready var HUD_Shoot_Ready: TextureProgressBar = $HUD/Icon2/HUD_Shoot_Ready

var is_destroyed = false

var aim_point_scale_ref: float = 7.5
var aim_point_original_scale: Vector2 = Vector2.ONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	tank_rigid.add_to_group("Player")
	
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	tank_rigid.velocimeter.connect(update_Velocimeter)
	
	HUD_Death_Screen.visible = false
	
	tank_rigid.shoot_recharge.connect(shoot_ready)
	
	update_HUD()
	
	tank_camera.player = tank_rigid
	
	aim_point_original_scale = HUD_aim.scale
	
	#await get_tree().physics_frame
	#Node.print_orphan_nodes()
	pass # Replace with function body.

func shoot_ready(charge: float) -> void:
	HUD_Shoot_Ready.value = charge

func _physics_process(delta: float) -> void:
	tank_camera.move_cam(tank_rigid.position, delta)
	#tank_rigid.allign_with_floor(delta)
	
	
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
	if is_destroyed:
		if Input.is_action_just_pressed("Shoot"):
			get_tree().reload_current_scene()
		return
	
	if Input.is_action_just_pressed("Reload"):
		get_tree().reload_current_scene()
		return
	
	var input_dir := Input.get_vector("Left","Right","Backward","Forward")
	
	#print(get_viewport().get_mouse_position())
	
	if Input.is_action_just_pressed("Shoot"):
		tank_rigid.shoot()
	
	tank_rigid.move(input_dir, delta)
	
	#tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	tank_rigid.rotate_turret_to_point_3d(tank_camera.get_mouse_3d_pos())

func update_HUD() -> void:
	update_AP(tank_rigid.armor_points)
	update_Score(tank_rigid.score)

func update_AP(ap: int) -> void:
	HUD_AP.text = (str(ap) +" AP")
	
	if ap <= 0:
		destruction()

func update_Score(score: int) -> void:
	HUD_Score.text = ("Score: "+str(score))

func update_Velocimeter(velocity: float) -> void:
	var final_vel = "%.2f" % (velocity * 5)
	HUD_Velocimeter.text = (final_vel+" Km/h")

func destruction() -> void:
		is_destroyed = true
		
		HUD_aim.visible = false
		HUD_mouse.visible = false
		HUD_Score.visible = false
		HUD_AP.visible = false
		HUD_Velocimeter.visible = false
		HUD_height_line.visible = false
		
		HUD_Death_Screen.visible = true
		
		return
	
