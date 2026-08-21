extends Area3D
class_name Projectile

var current_pos: Vector3 = Vector3.ZERO
var is_player: bool = true
var speed: float = 0.5
var base_speed: float = 0.5
var direction: Vector3 = Vector3(1,0,0)
var origin: Tank_Rigid
var damage: int = 20
var is_explosive: bool = false
var blast_rad: float = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_area_entered)
	base_speed = speed
	deactivate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move()


func set_origin(tank: Tank_Rigid) -> void:
	origin = tank
	is_player = origin.is_player

func shoot(pos: Vector3, rot: float) -> void:
	activate()
	current_pos = pos
	position = current_pos
	rotation.y = rot
	direction = Vector3(1,0,0)


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	visible = false
	#process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
func move() -> void:
	if direction == Vector3.ZERO:
		return
	
	var current_pos_2d: Vector2 = (Vector2(0,1).rotated(-rotation.y))
	global_position += Vector3(-current_pos_2d.y,0,current_pos_2d.x) * speed

func _on_area_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage,origin)
		#origin.get_score(damage)
		if not is_explosive:
			deactivate()
		else:
			detonate()


func detonate() -> void:
	
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = global_transform
	query.collision_mask = 1
	
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	query.exclude = [self]
	
	var space = get_world_3d().direct_space_state
	var targets = space.intersect_shape(query)
	
	var hitted_enemies = []
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			
			if current_collider.has_method("take_damage") or current_collider.has_method("detonate") :
				
				var raycast = PhysicsRayQueryParameters3D.create(global_position,current_collider.global_position)
				raycast.exclude = [self]
				
				raycast.collide_with_areas = true
				raycast.hit_from_inside = true
				
				var res = space.intersect_ray(raycast)
				
				#print(res," --|-- ", current_collider)
				
				if res and res.collider == current_collider:
					hitted_enemies.append(current_collider)
					
					if current_collider.has_method("take_damage"):
						current_collider.take_damage(damage,origin)
					if current_collider.has_method("detonate"):
						current_collider.detonate()
				
	
	deactivate()
