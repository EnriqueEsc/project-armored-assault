extends CharacterBody3D
class_name  Tank_Rigid



signal gets_enabled
signal gets_disabled
signal hp_changed (hp: int)
signal score_changed (score: int)


const max_speed = 3
const acceleration = 5
const tank_turn_speed = 0.025

var is_player: bool = false

var current_speed = max_speed
var score: int = 0

@onready var collision = $CollisionShape3D
@onready var tank_turret: Tank_turret = $Turret

var max_armor_points: int = 40
var armor_points: int = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func move(move: Vector2) -> void:
	rotate_y(-move.x * tank_turn_speed)
	
	var direction: Vector3 = transform.basis.z * move.y
	
	velocity = direction * current_speed
	
	move_and_slide()
	
	#var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	#position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed

func shoot() -> void:
	tank_turret.shoot()


func rotate_turret_to_point(point: Vector2) -> void:
	tank_turret.rotate_turret_to_point(point)

func get_aim_point(point: Vector2) -> Vector2:
	return tank_turret.get_aim_point(point)



func take_damage(damage: int, source: Tank_Rigid) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	print("Salud ",armor_points)
	
	
	hp_changed.emit(armor_points)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	gets_enabled.emit()
	hp_changed.emit(armor_points)
	score_changed.emit(score)

func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	gets_disabled.emit()


func get_score(score: int) -> void:
	self.score += score
	score_changed.emit(self.score)
