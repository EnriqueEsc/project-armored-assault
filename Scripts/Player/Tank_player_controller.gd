extends Node

@onready var tank_rigid: Tank_Rigid = $CharacterBody3D
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/Icon
@onready var HUD_aim: Sprite2D = $HUD/Icon2
@onready var HUD_dir: Sprite3D = $CharacterBody3D/Forward

@onready var projectile: Projectile = $Projectile

@onready var HUD_AP: RichTextLabel = $HUD/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	projectile.origin = tank_rigid
	tank_rigid.tank_turret.projectile = projectile
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	update_HUD()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input_dir := Input.get_vector("Left","Right","Backward","Forward")
	
	#print(get_viewport().get_mouse_position())
	
	if Input.is_action_just_pressed("Shoot"):
		tank_rigid.shoot()
	
	tank_rigid.move(input_dir)
	tank_camera.move_cam(tank_rigid.position)
	
	tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	HUD_mouse.position = get_viewport().get_mouse_position()
	
	HUD_aim.position = tank_rigid.get_aim_point(get_viewport().get_mouse_position())

func update_HUD() -> void:
	update_AP(tank_rigid.armor_points)
	update_Score(tank_rigid.score)

func update_AP(ap: int) -> void:
	HUD_AP.text = (str(ap) +" AP")

func update_Score(score: int) -> void:
	HUD_Score.text = ("Score: "+str(score))
