extends Node3D
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
@export var recoil_force: float = 1
@export var heat: float = 5.0
@export var status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None
@export var range: float = 25.0
var ignore = []

var original_speed: float = 10
var original_damage: int = 10
var orginal_is_explosive: bool = true
var original_blast_rad: float = 2
var original_blast_damage: float = 10
var original_recoil_force: float = 1
var original_heat: float = 5.0
var original_status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None
var original_range: float = 25.0
var original_color: Color = Color.YELLOW

signal activated(projectile: Projectile)
signal deactivated(projectile: Projectile)
signal explodes(pos: Vector3, blast_rad: float, blast_damage: float)
signal hits_enemy()

var detonated: bool = false

@export var blast_det_max_entities = 32

var effects_manager: Effects_Manager = null

@export var muzzle_flash_scale: float = 1.0

var fake_light: Mesh_Instance_3D_Effect = null
var fake_light_original_size: Vector2 = Vector2.ZERO

var origin_point: Vector3 = Vector3.ZERO




@export_group("Slug Settigns")
var slugs: Array[Projectile] = []
var slug_pref: PackedScene = null
var fixated_ignore: Array = []
@export var uses_slug: bool = false
@export_file("*.tscn") var slug_pref_path: String
@export var slug_num: int = 0
@export var recursivity: int = 0
@export var horizontal_disp: Vector2 = Vector2.ZERO
@export var vertical_disp: Vector2 = Vector2.ZERO

@onready var proy: MeshInstance3D = $Proy
@export var additional_proy_meshes: Array[MeshInstance3D] = []

var power_multiplier: float = 1.0

signal body_entered

@export var caster: ShapeCast3D = null

var stencil_color : Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	#area_entered.connect(_on_body_entered)
	base_speed = speed
	
	
	deactivate()
	
	await get_tree().physics_frame
	
	for c in get_children():
		if c is MeshInstance3D:
			set_emission_in_material(c)
	
	if is_instance_valid($CollisionShape3D):
		for c in $CollisionShape3D.get_children():
			if c is MeshInstance3D:
				set_emission_in_material(c)
	
	
	
	effects_manager = Effects_Manager.INSTANCE
	
	if proy:
		proy.layers = 2
	
	set_shape_cast()
	
	_additional_setup()
	
	_set_originals()
	
	var overlay = StandardMaterial3D.new()
	overlay.albedo_color.a = 0.0
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.stencil_mode = BaseMaterial3D.STENCIL_MODE_XRAY
	
	proy.material_overlay = overlay
	
	for a in additional_proy_meshes:
		if not is_instance_valid(a):
			continue
		a.material_overlay = overlay
	
	
	if not uses_slug:
		return
	
	if not slug_pref_path:
		slug_pref_path = scene_file_path
	
	if slug_pref_path:
		slug_pref = load(slug_pref_path)
	
	if not slug_pref:
		return
	
	if recursivity < 1:
		return
	
	if slug_num < 1:
		return
	
	slugs = []
	for i in slug_num:
		var pref = slug_pref.instantiate() as Projectile
		if not is_instance_valid(pref):
			continue
		pref.damage = damage
		pref.blast_rad = blast_rad
		pref.base_speed = base_speed
		pref.blast_damage = blast_damage
		pref.blast_det_max_entities = blast_det_max_entities
		pref.recursivity = recursivity - 1
		pref.origin = origin
		pref.stencil_color = stencil_color
		get_tree().current_scene.call_deferred("add_child",pref)
		slugs.append(pref)
		#fixated_ignore.append(pref.get_rid())
		ignore.append(pref)
	
	for s in slugs:
		s.ignore = (fixated_ignore)
		s.ignore.append_array(ignore)

func set_shape_cast() -> void:
	var col = $CollisionShape3D
	caster = ShapeCast3D.new()
	var shape = col.shape.duplicate()
	caster.shape = shape
	caster.collide_with_areas = false
	caster.collide_with_bodies = true
	call_deferred("add_child",caster)
	col.queue_free()

func _set_originals() -> void:
	original_speed = speed
	original_damage = damage
	orginal_is_explosive = is_explosive
	original_blast_rad = blast_rad
	original_blast_damage = blast_damage
	original_recoil_force = recoil_force
	original_heat = heat
	original_status_effect = status_effect
	original_range = range


func modify_parameters(spd: float = 1.0, dmg: float = 1.0, rang: float = 1.0, sts: Vehicle_Rigid.StatusEffects = original_status_effect, exp: bool = orginal_is_explosive, blst_dmg: float = 1.0, blst_rd: float = 1.0, ht: float = 1.0, rec: float = 1.0) -> void:
	speed = original_speed * spd
	damage = original_damage * dmg
	is_explosive = exp
	blast_damage = original_blast_damage * blst_dmg
	blast_rad = original_blast_rad * blst_rd
	recoil_force = original_recoil_force * rec
	heat = original_heat * ht
	range = original_range * rang
	status_effect = sts
	
	
	if not is_instance_valid(proy):
		return
	var mat = proy.material_override as StandardMaterial3D
	if not is_instance_valid(mat):
		return
	original_color = mat.albedo_color

func _additional_setup() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)


func set_origin(vehicle: Vehicle_Rigid) -> void:
	origin = vehicle
	hits_enemy.connect(origin.send_hit_signal)
	is_player = origin.is_player
	
	fixated_ignore = [origin.get_rid()]
	
	
	set_projectile_team(origin.current_team)

func set_projectile_team(team: Basic_AI.Team) -> void:
	match team:
		Basic_AI.Team.ENEMY:
			stencil_color = Color.RED
		Basic_AI.Team.ALLY:
			stencil_color = Color.GREEN

func _additional_shoot_process() -> void:
	pass

func shoot(pos: Vector3, rot: Vector2, pot: bool = false, mult: float = 2.0) -> void:
	activate()
	
	if pot:
		power_multiplier = mult
		change_material_color(Color.BLUE)
	elif power_multiplier != 1.0:
		power_multiplier = 1.0
		change_material_color()
	
	var overlay = proy.material_overlay
	if overlay and proy.material_overlay.stencil_color != stencil_color:
		proy.material_overlay.stencil_color = stencil_color
		
	current_pos = pos
	position = current_pos
	
	
	origin_point = global_position
	
	
	rotation.y = rot.y
	rotation.x = rot.x
	direction = Vector3(1,0,0)
	
	_additional_shoot_process()
	
	if slugs.is_empty():
		return
	
	for s in slugs:
		#s.ignore = (fixated_ignore)
		#s.ignore.append_array(ignore)
		
		s.shoot(global_position,Vector2(rotation.x + deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y)),rotation.y + deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))),pot,mult)
	
	rotation.x += deg_to_rad(randf_range(vertical_disp.x,vertical_disp.y))
	rotation.y += deg_to_rad(randf_range(horizontal_disp.x,horizontal_disp.y))
	


func activate() -> void:
	visible = true
	set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	
	if is_explosive:
		detonated = false
	
	activated.emit(self)

func deactivate() -> void:
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	_additional_deactivate_process()
	
	deactivated.emit(self)

func _additional_deactivate_process() -> void:
	pass

func move(delta: float) -> void:
	if direction == Vector3.ZERO:
		return
	
	if origin_point.distance_to(global_position) > range:
		deactivate()
		return
	
	var current_pos_2d: Vector2 = (Vector2(0,1).rotated(-rotation.y))
	var dist = speed * delta
	var mov = global_basis.z * dist
	
	caster.target_position = Vector3(0,0,dist)
	caster.force_shapecast_update()
	
	if caster.is_colliding():
		for i in range(caster.get_collision_count()):
			var col = caster.get_collider(i)
			if is_instance_valid(col):
				body_entered.emit(col)
	
	global_position += global_basis.z * speed * delta

func _on_body_entered(body):
	#print(body.collider.get_parent.name)
	
	#print(body == origin)
	
	if body == origin:
		return
	
	if ignore.has(body):
		return
	
	#print(body)
	
	if body is Vehicle_Rigid or body is Emplacement:
		hits_enemy.emit()
	
	if body is Vehicle_Rigid:
		body.shakes.emit(0.1,0.2)
		
	
	if body.has_method("take_damage"):
		direction = Vector3.ZERO
		#origin.projectile_to_pool(self)
		body.take_damage(damage * power_multiplier, origin, global_position, status_effect)
		
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		#origin.get_score(damage)
		if not is_explosive:
			deactivate()
		else:
			detonate()
	elif body.has_method("detonate"):
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.sparks_from_pool(global_position)
		body.detonate()
		if not is_explosive:
			deactivate()
		else:
			detonate()
	else:
		direction = Vector3.ZERO
		if effects_manager:
			effects_manager.failed_sparks_from_pool(global_position)
		if not is_explosive:
			#deform_shader(body,global_position)
			deactivate()
		else:
			#deform_shader(body,global_position)
			detonate()


func detonate() -> void:
	if detonated:
		return
	
	detonated = true
	
	if not is_explosive:
		return
	
	
	if effects_manager:
		effects_manager.explosion_3d_from_pool(global_position,blast_rad)
	
	explodes.emit(global_position,blast_rad,blast_damage * power_multiplier)
	
	
	var explosion = SphereShape3D.new()
	explosion.radius = blast_rad
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = explosion
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	#query.exclude = [self.get_rid()] 
	
	var space = get_world_3d().direct_space_state
	
	var targets = space.intersect_shape(query,blast_det_max_entities)
	
	var hitted_enemies = []
	
	var ray_origin = global_position + Vector3(0.0, 0.5, 0.0)
	
	for t in targets:
		var current_collider = t.collider
		
		if current_collider and not hitted_enemies.has(current_collider):
			
			#print("boom ",current_collider)
			
			if current_collider.has_method("take_explosion") or current_collider.has_method("detonate"):
				#current_collider.take_explosion(blast_damage, origin, global_position, blast_rad)
				hitted_enemies.append(current_collider)
				continue
			
			if current_collider.has_method("take_damage"):
				
				var target_center = current_collider.global_position + Vector3(0.0, 0.5, 0.0)
				var raycast = PhysicsRayQueryParameters3D.create(ray_origin, target_center)
				
				#raycast.exclude = [self.get_rid()]
				
				for h in hitted_enemies:
					raycast.exclude.append(h)
				
				#raycast.collide_with_areas = true
				raycast.collide_with_areas = false
				raycast.collide_with_bodies = true
				
				raycast.hit_from_inside = true 
				
				var res = space.intersect_ray(raycast)
				
				
				if res and res.collider == current_collider:
					Effects_Manager.INSTANCE.sparks_from_pool(res.position)
					hitted_enemies.append(current_collider)
					#print(current_collider)
					if current_collider.has_method("take_damage"):
						pass
						#current_collider.take_damage(blast_damage, origin, global_position)
				
	for t in hitted_enemies:
		#Effects_Manager.INSTANCE.sparks_from_pool(t.global_position)
		
		if (t is Vehicle_Rigid and t != origin) or t is Emplacement:
			hits_enemy.emit()
			
		
		#print("olaaaa ",t," | ",hits_enemy.is_connected(origin.send_hit_signal))
		if t.has_method("take_explosion"):
			t.call_deferred("take_explosion", blast_damage * power_multiplier, origin, global_position, blast_rad)
			
			#print(t)
			continue
	
		if t.has_method("take_damage"):
			t.call_deferred("take_damage", blast_damage * power_multiplier, origin, global_position, status_effect)
			
		if t.has_method("recoil"):
			#print(t)
			t.shakes.emit(0.4,0.6)
			t.call_deferred("recoil",global_position.direction_to(t.global_position),blast_rad * blast_damage)
		
			
		if t.has_method("detonate"):
			t.call_deferred("detonate")
			continue
	deactivate()


func set_emission_in_material(mesh: MeshInstance3D, enable_emission: bool = Settings_Manager.INSTANCE.enable_emmisions) -> void:
		if mesh.material_override and mesh.material_override is StandardMaterial3D:
			mesh.material_override.emission_enabled = enable_emission
		if mesh.mesh is QuadMesh:
			if not enable_emission:
				mesh.queue_free()
			elif mesh is Mesh_Instance_3D_Effect:
				fake_light = mesh as Mesh_Instance_3D_Effect
				fake_light_original_size = mesh.mesh.size

func change_material_color(color: Color = original_color) -> void:
	if not is_instance_valid(proy):
		return
	var mat = proy.material_override as StandardMaterial3D
	if not is_instance_valid(mat):
		return
	mat.albedo_color = color
	mat.emission = color
	proy.material_override = mat
	if not is_instance_valid(fake_light):
		return
	
	fake_light.set_instance_shader_parameter("light_color",color)
