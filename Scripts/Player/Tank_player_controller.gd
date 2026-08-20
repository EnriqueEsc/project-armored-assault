extends Node

@onready var tank_rigid: Tank_Rigid = $CharacterBody3D
@onready var tank_camera: Tank_camera = $Camera3D
@onready var tank_turret: Tank_turret = $CharacterBody3D/Turret

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input_dir := Input.get_vector("Left","Right","Backward","Forward")
	
	#print(get_viewport().get_mouse_position())
	
	tank_rigid.move(input_dir)
	tank_camera.move_cam(tank_rigid.position)
	
	tank_turret.rotate_turret_to_point(get_viewport().get_mouse_position())
