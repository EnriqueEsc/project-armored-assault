extends Node

@onready var tank_rigid: Tank_Rigid = $Tank_Player
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/Icon
@onready var HUD_aim: Sprite2D = $HUD/Icon2
@onready var HUD_dir: Sprite3D = $Tank_Player/Forward

@onready var HUD_AP: RichTextLabel = $HUD/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Score

@onready var HUD_Death_Screen: Control = $HUD/Death_Screen

var is_destroyed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	
	HUD_Death_Screen.visible = false
	
	update_HUD()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_destroyed:
		if Input.is_action_just_pressed("Shoot"):
			get_tree().change_scene_to_file("res://Scenes/test.tscn")
		return
	
	var input_dir := Input.get_vector("Left","Right","Backward","Forward")
	
	#print(get_viewport().get_mouse_position())
	
	if Input.is_action_just_pressed("Shoot"):
		tank_rigid.shoot()
	
	tank_rigid.move(input_dir, delta)
	tank_camera.move_cam(tank_rigid.position)
	
	#tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	tank_rigid.rotate_turret_to_point_3d(tank_camera.get_mouse_3d_pos())
	#print(tank_camera.get_mouse_3d_pos())
	HUD_mouse.position = get_viewport().get_mouse_position()
	
	#print(tank_rigid.get_aim_point_3d())
	HUD_aim.position = tank_camera.unproject_position(tank_rigid.get_aim_point_3d(tank_rigid.tank_turret.global_position.distance_to(tank_camera.get_mouse_3d_pos())))
	#HUD_aim.position = tank_rigid.get_aim_point(get_viewport().get_mouse_position())

func update_HUD() -> void:
	update_AP(tank_rigid.armor_points)
	update_Score(tank_rigid.score)

func update_AP(ap: int) -> void:
	HUD_AP.text = (str(ap) +" AP")
	
	if ap <= 0:
		destruction()

func update_Score(score: int) -> void:
	HUD_Score.text = ("Score: "+str(score))

func destruction() -> void:
		is_destroyed = true
		
		HUD_aim.visible = false
		HUD_mouse.visible = false
		HUD_Score.visible = false
		HUD_AP.visible = false
		
		HUD_Death_Screen.visible = true
		
		return
	
