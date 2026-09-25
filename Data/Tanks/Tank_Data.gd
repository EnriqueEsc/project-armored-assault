extends Resource
class_name Tank_Data

@export var tank_Name: String = "MK_0 Tonnel"
@export var cost: int = 1
@export var max_speed: float = 3.0
@export var acceleration: float = 5.0
@export var turn_speed: float = 1.0
@export var turning_velocity: float = 0
@export var turning_acceleration: float = 0.2
@export var friction: float = 1
@export var traction: float = 5
@export var max_armor_points: int = 40
@export var fire_rate_prim: float = 2


func _apply_values(tank: Tank_Rigid) -> void:
	tank.max_speed = max_speed
	tank.current_speed = max_speed
	tank.acceleration = acceleration
	tank.turn_speed = turn_speed
	tank.turning_velocity = turning_velocity
	tank.turning_acceleration = turning_acceleration
	tank.friction = friction
	tank.traction = traction
	#tank.fire_rate_prim = fire_rate_prim
	tank.max_armor_points = max_armor_points
	tank.armor_points = max_armor_points
