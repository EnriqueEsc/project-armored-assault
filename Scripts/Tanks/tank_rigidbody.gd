extends CharacterBody3D
class_name  Tank_Rigid



signal gets_enabled
signal gets_disabled
signal hp_changed (hp: int)
signal score_changed (score: int)


@export var max_speed: float = 3.0
@export var acceleration: float = 5.0
@export var tank_turn_speed: float = 1.0


@export var turning_velocity: float = 0
@export var turning_acceleration: float = 0.2

@export var is_player: bool = false

var current_speed = max_speed
var score: int = 0
@export var friction: float = 1

var direction: Vector3 = Vector3.ZERO

@onready var collision = $CollisionShape3D
@onready var tank_turret: Tank_turret = $Turret

@export var max_armor_points: int = 40
var armor_points: int = 40


var time_controller: Time_Controller
@export var fire_rate_prim: float = 2
var last_shoot_prim: float = -10

var time_passed: float = 0

signal shoot_recharge(charge: float)
signal velocimeter(velocity: float)
signal got_hit(source: Tank_Rigid, impact_point: Vector3)

@export var allign_speed: float = 3



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_controller = Time_Controller.INSTANCE
	tank_turret.recoil.connect(recoil)
	
	tank_turret.origin = self
	tank_turret.create_projectiles()
	
	time_passed = fire_rate_prim
	

func calculate_charge(delta: float) -> void:
	time_passed += delta
	var percent = time_passed / fire_rate_prim
	percent = clampf(percent,0,1)
	percent *= 100
	shoot_recharge.emit(percent)

func recoil(dir: Vector3) -> void:
	var push = Vector3.ZERO.move_toward(dir, friction)
	#push = Vector3(push.x, 0 ,push.z)
	velocity += push

func allign_with_floor(delta: float) -> void:
	var normal: Vector3 = Vector3.UP
	
	if is_on_floor():
		normal = get_floor_normal()
	var current_transform = global_transform
	var current_right = current_transform.basis.x
	var forward = current_right.cross(normal).normalized()
	var right = normal.cross(forward).normalized()
	var target_basis = Basis(right,normal,forward)
	var new_basis = current_transform.basis.slerp(target_basis, allign_speed * delta)
	global_transform.basis = new_basis.orthonormalized()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	allign_with_floor(delta)
	
	calculate_charge(delta)
	
	if direction:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, friction * delta)
		velocity.z = lerpf(velocity.z, 0.0, friction * delta)
	
	velocimeter.emit(velocity.length())
	
	turning_velocity = lerpf(turning_velocity,0,friction * 5 * delta)
	rotate_y(turning_velocity)
	
	var pre_impact_vel: Vector3 = velocity
	
	move_and_slide()
	
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		'''
		if collider is RigidBody3D:
			var dir = -collision.get_normal()
			var push = dir * velocity.length()
			
			collider.apply_central_force(push)
		'''
		
		var normal = collision.get_normal()
		var impact = pre_impact_vel.dot(-normal)
		
		if impact > 2.0:
			if collider is RigidBody3D:
				var push = -normal * impact
				collider.apply_central_force(push)
				
			#if collider is Building:
			if collider.has_method("take_damage"):
				var impact_damage = (armor_points/20.0) * impact
				collider.take_damage(impact_damage, self, global_position)
		
		
		#Para seguir desgastando las estructuras si se sigue avanzando
		if collider is Building and impact != 0:
			collider.take_damage(1 ,self, global_position)


func move(move: Vector2, delta: float) -> void:
	#rotate_y(-move.x * tank_turn_speed * delta)
	
	turning_velocity = lerpf(turning_velocity, -move.x * tank_turn_speed, turning_acceleration * delta)
	
	direction = transform.basis.z * move.y
	
	#var current_pos_2d: Vector2 = (Vector2(0,move.y).rotated(-rotation.y))
	#position += Vector3(current_pos_2d.x,0,current_pos_2d.y) * current_speed

func shoot() -> void:
	
	if last_shoot_prim + fire_rate_prim >= time_controller.running_time:
		return
	last_shoot_prim = time_controller.running_time
	
	tank_turret.shoot()
	
	time_passed = 0

func rotate_turret_to_point_3d(point: Vector3) -> void:
	tank_turret.rotate_turret_to_point_3d(point)

func rotate_turret_to_point(point: Vector2) -> void:
	tank_turret.rotate_turret_to_point(point)

func get_aim_point(point: Vector2) -> Vector2:
	return tank_turret.get_aim_point(point)

func get_aim_point_3d(distance: float) -> Vector3:
	return tank_turret.get_aim_point_3d(distance)


func take_damage(damage: int, source: Tank_Rigid, impact_point: Vector3) -> void:
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
		return
	
	got_hit.emit(source, impact_point)


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
