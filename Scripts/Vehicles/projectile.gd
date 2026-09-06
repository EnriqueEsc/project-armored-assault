extends Area3D
class_name Projectile

var current_pos: Vector3 = Vector3.ZERO
var is_player: bool = true
@export var speed: float = 10
@export var base_speed: float = 0.5
var direction: Vector3 = Vector3(1,0,0)
var origin: Vehicle_Rigid
@export var damage: int = 10
@export var is_explosive: bool = true
@export var blast_rad: float = 2
@export var blast_damage: float = 10
var ignore = []

signal deactivated(projectile: Projectile)

var detonated: bool = false

@export var blast_det_max_entities = 32

var effects_manager: Effects_Manager = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	#area_entered.connect(_on_body_entered)
	base_speed = speed
	
	deactivate()
	
	await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)


func set_origin(vehicle: Vehicle_Rigid) -> void:
	origin = vehicle
	is_player = origin.is_player

func shoot(pos: Vector3, rot: Vector2) -> void:
	activate()
	current_pos = pos
	position = current_pos
	rotation.y = rot.y
	rotation.x = rot.x
	direction = Vector3(1,0,0)


func activate() -> void:
	visible = true
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if is_explosive:
		detonated = false

func deactivate() -> void:
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	deactivated.emit(self)

func move(delta: float) -> void:
	if direction == Vector3.ZERO:
		return
	
	var current_pos_2d: Vector2 = (Vector2(0,1).rotated(-rotation.y))
	global_position += global_basis.z * speed * delta

func _on_body_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if ignore.has(body):
		return
	
	#print(body)
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage, origin, global_position)
		#origin.get_score(damage)
		if not is_explosive:
			deactivate()
		else:
			detonate()
	elif body.has_method("detonate"):
		direction = Vector3.ZERO
		body.detonate()
		if not is_explosive:
			deactivate()
		else:
			detonate()
	else:
		direction = Vector3.ZERO
		if not is_explosive:
			deactivate()
		else:
			detonate()


func detonate() -> void:
	if detonated:
		return
	
	detonated = true
	
	if not is_explosive:
		return
	
	if effects_manager:
		effects_manager.explosion_from_pool(global_position)
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	query.exclude = [self.get_rid()] 
	
	var space = get_world_3d().direct_space_state
	
	var targets = space.intersect_shape(query,blast_det_max_entities)
	
	var hitted_enemies = []
	
	var ray_origin = global_position + Vector3(0.0, 0.5, 0.0)
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			
			if current_collider.has_method("take_explosion") or current_collider.has_method("detonate"):
				#current_collider.take_explosion(blast_damage, origin, global_position, blast_rad)
				hitted_enemies.append(current_collider)
				continue
			
			if current_collider.has_method("take_damage"):
				
				
				var target_center = current_collider.global_position + Vector3(0.0, 0.5, 0.0)
				var raycast = PhysicsRayQueryParameters3D.create(ray_origin, target_center)
				
				raycast.exclude = [self.get_rid()]
				
				for h in hitted_enemies:
					raycast.exclude.append(h)
				
				raycast.collide_with_areas = true
				raycast.collide_with_bodies = true
				
				raycast.hit_from_inside = true 
				
				var res = space.intersect_ray(raycast)
				
				if res and res.collider == current_collider:
					hitted_enemies.append(current_collider)
					#print(current_collider)
					if current_collider.has_method("take_damage"):
						pass
						#current_collider.take_damage(blast_damage, origin, global_position)
				
	for t in hitted_enemies:
		if t.has_method("take_explosion"):
			t.call_deferred("take_explosion", blast_damage, origin, global_position, blast_rad)
			continue
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage, origin, global_position)
		
		if t.has_method("recoil"):
			#print(t)
			t.call_deferred("recoil",global_position.direction_to(t.global_position),blast_rad)
	deactivate()
