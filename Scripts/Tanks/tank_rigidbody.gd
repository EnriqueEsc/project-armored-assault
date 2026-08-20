extends CharacterBody3D
class_name  Tank_Rigid

const max_speed = 0.05
const acceleration = 5
const tank_turn_speed = 0.025

var current_speed = max_speed

@onready var collision = $CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func move(move: Vector2) -> void:
	rotate_y(-move.x * tank_turn_speed)
	
	var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed
