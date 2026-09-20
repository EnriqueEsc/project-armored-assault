extends StaticBody3D
class_name Mine

var current_pos: Vector3 = Vector3.ZERO
var is_player: bool = true
var origin: Tank_Rigid
var damage: int = 1
var blast_rad: float = 1

var detonated: bool = false

@onready var trigger: Area3D = $Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	trigger.body_entered.connect(_on_area_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_origin(tank: Tank_Rigid) -> void:
	origin = tank
	is_player = origin.is_player

func shoot(pos: Vector3, rot: float) -> void:
	activate()
	current_pos = pos
	position = current_pos
	rotation.y = rot


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	queue_free()
	visible = false
	#process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	

func _on_area_entered(body: Node3D):
	#print(body..get_parent.name)
	
	#print("Holaaaaaa")
	
	if body.has_method("take_damage"):
		#origin.projectile_to_pool(self)
		body.take_damage(damage,origin,global_position)
		detonate()
		if origin:
			origin.get_score(damage)

func detonate() -> void:
	
	print("MINA")
	
	if detonated:
		return
	
	detonated = true
	
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
				
				var res = space.intersect_ray(raycast)
				
				if res and res.collider == current_collider:
					hitted_enemies.append(current_collider)
					
					if current_collider.has_method("take_damage"):
						current_collider.take_damage(damage,origin,global_position)
					if current_collider.has_method("detonate"):
						current_collider.detonate()
					if current_collider.has_method("stagger"):
						current_collider.stagger()
				
	
	deactivate()
