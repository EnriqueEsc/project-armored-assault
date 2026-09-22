extends Node3D
class_name Building_V2

var levels: Array[Building_Chunk] = []

var damage_zone: ShapeCast3D = null
var building_bounds: Vector2 = Vector2.ZERO

var effects_manager: Effects_Manager = null

var physics_tick_counter: int = 6
@export var crush_update_frequency: int = 5

var destroyed: bool = false


@export var inner_pref_mesh_instance: MeshInstance3D
@export var pref_mesh: Mesh
var multimesh_instance: MultiMeshInstance3D = null

var multimesh: MultiMesh



@export var side_pref_mesh_instance: MeshInstance3D
var side_pref_mesh: Mesh
var side_multimesh_instance: MultiMeshInstance3D = null

var side_multimesh: MultiMesh



@export var corner_pref_mesh_instance: MeshInstance3D
var corner_pref_mesh: Mesh
var corner_multimesh_instance: MultiMeshInstance3D = null

var corner_multimesh: MultiMesh



@export var street_pref_mesh_instance: MeshInstance3D
var street_pref_mesh: Mesh
var street_multimesh_instance: MultiMeshInstance3D = null

var street_multimesh: MultiMesh

signal got_destroyed

var col_size_x: int = 0
var col_size_y: int = 0
var col_size_z: int = 0

var lowest_height: float = INF

var combiner: CSGCombiner3D = null

@export var material: Material = null

var csg_active: bool = true
var see_trough: bool = false

var player_ref: Vehicle_Rigid = null
var max_shake_distance: float = 10.0

var ignore_player_shake: bool = false

var vis_ref: MeshInstance3D = null

var counter_blocks: int = 0

var ghost_colission: Area3D = null

func _ready() -> void:
	csg_active = Settings_Manager.INSTANCE.use_csg
	see_trough = Settings_Manager.INSTANCE.see_trough_buildings
	
	if inner_pref_mesh_instance:
		pref_mesh = inner_pref_mesh_instance.mesh
	
	if side_pref_mesh_instance:
		side_pref_mesh = side_pref_mesh_instance.mesh
	else:
		side_pref_mesh = pref_mesh
	
	if corner_pref_mesh_instance:
		corner_pref_mesh = corner_pref_mesh_instance.mesh
	else:
		corner_pref_mesh = pref_mesh
		
	if street_pref_mesh_instance:
		street_pref_mesh = street_pref_mesh_instance.mesh
	else:
		street_pref_mesh = pref_mesh
	
	
	if csg_active:
		combiner = CSGCombiner3D.new()
		add_child(combiner)
		combiner.use_collision = false
	else:
		multimesh_instance = MultiMeshInstance3D.new()
		add_child(multimesh_instance)
		
		side_multimesh_instance = MultiMeshInstance3D.new()
		add_child(side_multimesh_instance)
		
		corner_multimesh_instance = MultiMeshInstance3D.new()
		add_child(corner_multimesh_instance)
		
		street_multimesh_instance = MultiMeshInstance3D.new()
		add_child(street_multimesh_instance)
	
	for c in get_children():
		if c is MeshInstance3D:
			vis_ref = c
		if c is Building_Chunk:
			levels.append(c)
			c.got_destroyed.connect(destroy_chunk.bind(c))
	if not levels.is_empty():
		levels[0].got_destroyed.connect(destroy_basement)
		building_bounds = levels[0].building_bounds
		set_shape_cast()
		set_ghost_colission()
	set_physics_process(false)
	
	if vis_ref:
		vis_ref.visible = false
	
	for i in 10:
		await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE
	
	init_grid()
	
	player_ref = get_tree().get_first_node_in_group("Player") as Vehicle_Rigid
	


func init_grid() -> void:
	if levels.is_empty():
		return
	
	
	lowest_height = levels[0].lowest_height
	
	col_size_x = levels[0].building_bounds.x
	col_size_y = levels.size()
	col_size_z = levels[0].building_bounds.y
	
	if not csg_active:
		#print("ola")
		multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
		side_multimesh = MultiMesh.new()
		side_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
		corner_multimesh = MultiMesh.new()
		corner_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
		street_multimesh = MultiMesh.new()
		street_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
		
		if see_trough:
			pref_mesh.surface_set_material(0,material)
			if side_pref_mesh:
				side_pref_mesh.surface_set_material(0,material)
			if corner_pref_mesh:
				corner_pref_mesh.surface_set_material(0,material)
			if street_pref_mesh:
				street_pref_mesh.surface_set_material(0,material)
				
		street_multimesh.mesh = street_pref_mesh
		street_multimesh.instance_count = levels[0].blocks_of_type(Building_Block_V2.Block_Types.SIDE)
		
		
		multimesh.mesh = pref_mesh
		multimesh.instance_count = levels.size() * levels[0].blocks_of_type(Building_Block_V2.Block_Types.INNER)
		
		side_multimesh.mesh = side_pref_mesh
		side_multimesh.instance_count = (levels.size() - 1) * levels[0].blocks_of_type(Building_Block_V2.Block_Types.SIDE)
		
		corner_multimesh.mesh = corner_pref_mesh
		corner_multimesh.instance_count = levels.size() * levels[0].blocks_of_type(Building_Block_V2.Block_Types.CORNER)
		
		#print("Inner ",multimesh.instance_count)
		#print("Side ",side_multimesh.instance_count)
		#print("Corner ",corner_multimesh.instance_count)
		#print("Street ",street_multimesh.instance_count)
		
	var start_x = -col_size_x * 0.5 + 1 * 0.5
	var start_y = 1 * 0.0
	var start_z = -col_size_z * 0.5 + 1 * 0.5

	var street_counter = 0
	var counter = 0
	var side_counter = 0
	var corner_counter = 0
	
	
	for c in levels:
		c.damage_zone = damage_zone
		c.building_half_extents = damage_zone.shape.size / 2.0
		c.building_max_radius = c.building_half_extents.length()
		for b in c.blocks:
			var pos = Vector3(b.position.x,b.global_position.y - global_position.y,b.position.z)

			var transform = Transform3D.IDENTITY

			#transform = transform.rotated(Vector3.UP,randf_range(0.0, TAU))
			if levels[0].blocks.has(b) and b.block_type == b.Block_Types.SIDE:
				b.block_type = b.Block_Types.STREET
			transform.origin = pos
			
			if csg_active:
				var blok: CSGBox3D = CSGBox3D.new()
				blok.size = Vector3(2,2,1)
				if see_trough:
					blok.material = material
				combiner.add_child(blok)
				blok.position = pos
				b.got_destroyed.connect(destroy_b.bind(blok))
			else:
				#print(b.block_type)
				transform.basis = Basis.from_euler(Vector3(0.0, deg_to_rad(b.block_visual_rotation), 0.0))
				if b.block_type == b.Block_Types.STREET:
					street_multimesh.set_instance_transform(street_counter, transform)
					b.id = street_counter
					b.got_destroyed.connect(destroy_block.bind(street_counter))
					street_counter += 1
				if b.block_type == b.Block_Types.INNER:
					multimesh.set_instance_transform(counter, transform)
					b.id = counter
					b.got_destroyed.connect(destroy_block.bind(counter))
					counter += 1
				if b.block_type == b.Block_Types.SIDE:
					side_multimesh.set_instance_transform(side_counter, transform)
					b.id = side_counter
					b.got_destroyed.connect(destroy_block.bind(side_counter))
					side_counter += 1
				if b.block_type == b.Block_Types.CORNER:
					corner_multimesh.set_instance_transform(corner_counter, transform)
					b.id = corner_counter
					b.got_destroyed.connect(destroy_block.bind(corner_counter))
					corner_counter += 1
			#b.queue_free()
			#var tree: Tree_data = Tree_data.new(1,counter, multimesh_instance.to_global(transform.origin) ,Vector2i(x,z))
			#tree.got_destroyed.connect(destroy_tree)
			#tree.got_burnt.connect(burn_tree)
			#tree_grid[x][z] = tree
			#print("[",x,"][",z,"]"," ",tree_grid[x][z])

	
	counter_blocks = counter
	#active_count = counter
	if not csg_active:
		#print("adio")
		multimesh_instance.multimesh = multimesh
		#multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		side_multimesh_instance.multimesh = side_multimesh
		#side_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corner_multimesh_instance.multimesh = corner_multimesh
		#corner_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		street_multimesh_instance.multimesh = street_multimesh
		#street_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		#print("Inner ",counter_blocks)
		#print("Side ",side_counter)
		#print("Corner ",corner_counter)
		#print("Street ",street_counter)
		
		var mesh = multimesh_instance.multimesh.mesh
		#print(mesh.resource_name," Inner | Superficies: ",mesh.get_surface_count())
		mesh = side_multimesh_instance.multimesh.mesh
		#print(mesh.resource_name," Side | Superficies: ",mesh.get_surface_count())
		mesh = corner_multimesh_instance.multimesh.mesh
		#print(mesh.resource_name," Corner | Superficies: ",mesh.get_surface_count())
		mesh = street_multimesh_instance.multimesh.mesh
		#print(mesh.resource_name," Street | Superficies: ",mesh.get_surface_count())


func set_ghost_colission() -> void:
	ghost_colission = Area3D.new()
	
	var cube = BoxShape3D.new()
	var col = CollisionShape3D.new()
	col.shape = cube
	
	#damage_zone.collide_with_areas = true
	
	col.shape.size = Vector3(building_bounds.x,5,building_bounds.y)
	
	call_deferred("add_child",ghost_colission)
	ghost_colission.call_deferred("add_child",col)
	if not levels.is_empty():
		ghost_colission.call_deferred("set_global_position", levels[0].global_position)
	else:
		ghost_colission.call_deferred("set_global_position", global_position)


func set_shape_cast() -> void:
	damage_zone = ShapeCast3D.new()
	
	var cube = BoxShape3D.new()
	damage_zone.shape = cube
	
	#damage_zone.collide_with_areas = true
	
	damage_zone.shape.size = Vector3(building_bounds.x,5,building_bounds.y)
	
	get_tree().current_scene.call_deferred("add_child",damage_zone)
	if not levels.is_empty():
		damage_zone.call_deferred("set_global_position", levels[0].global_position)
	else:
		damage_zone.call_deferred("set_global_position", global_position)
	#print(damage_zone.global_position)
	#damage_zone.global_position = global_position
	damage_zone.enabled = false



func crush_below() -> void:
	ignore_player_shake = false
	damage_zone.force_shapecast_update()
	
	for i in damage_zone.get_collision_count():
		#print(i)
		var collider = damage_zone.get_collider(i)
		if collider:
			if collider.has_method("take_damage"):
				#print(collider)
				collider.take_damage(10,null,collider.global_position)
			if collider.has_method("detonate"):
				collider.detonate()
			if collider is Vehicle_Rigid:
				ignore_player_shake = collider == player_ref
				collider.gets_crushed.emit()
				collider.shakes.emit(1.0,1.0)

func shake_player() -> void:
	#print("OLA",damage_zone.global_position.distance_to(player_ref.global_position))
	var distance = damage_zone.global_position.distance_to(player_ref.global_position)
	if distance < max_shake_distance:
		var factor: float = (max_shake_distance - distance) / max_shake_distance
		#print("ADIO")
		player_ref.shakes.emit(1.0,(1.0 * factor))

func _physics_process(delta: float) -> void:
	
	
	if not destroyed:
		return
	
	global_position -= global_basis.y * delta * 2
	
	physics_tick_counter += 1
	if physics_tick_counter >= crush_update_frequency:
		physics_tick_counter = 0
		destruction()


func destruction() -> void:
	var emmit_collapse_effect: bool = true
	
	var chunk: Array[Building_Block_V2] = []
	
	for l in levels:
		for b in l.blocks:
			if not is_instance_valid(b):
				continue
			if b.global_position.y <= lowest_height + 0.1:
				#b.got_destroyed.emit(b)
				#b.deactivate()
				#crush_below()
				emmit_collapse_effect = true
				chunk.append(b)
		
		if chunk.is_empty():
			return
		
		for c in chunk:
			c.got_destroyed.emit(c,c.block_type)
			c.deactivate()
		
	crush_below()
	
	if player_ref and not ignore_player_shake:
		shake_player()
	
	if emmit_collapse_effect and effects_manager:
		effects_manager.collapse_from_pool(damage_zone.global_position)

func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("disabled",false)
	#set_deferred("monitoring", true)
	#set_deferred("monitorable", true)

func destroy_chunk(chunk: Building_Chunk) -> void:
	
	levels.erase(chunk)
	if levels.is_empty():
		for l in levels:
			l.deactivate_collisions()
		#damage_zone.enabled = true
		deactivate()
	
func destroy_basement() -> void:
	for l in levels:
		l.deactivate_collisions()
	destroyed = true
	shake_player()
	set_physics_process(true)

func deactivate() -> void:
	got_destroyed.emit()
	#print("siuuuuuuu V2")
	damage_zone.queue_free()
	queue_free()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("disabled",true)
	#set_deferred("monitoring", false)
	#set_deferred("monitorable", false)
	return
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	

func destroy_block(bld:Building_Block_V2, type: Building_Block_V2.Block_Types, id: int) -> void:
	var mm: MultiMesh = null
	
	#print("INTENTANDO DESTRUIR ",id," ",str(type))
	
	match type:
		Building_Block_V2.Block_Types.INNER:
			mm = multimesh_instance.multimesh
		Building_Block_V2.Block_Types.SIDE:
			mm = side_multimesh_instance.multimesh
		Building_Block_V2.Block_Types.CORNER:
			mm = corner_multimesh_instance.multimesh
		Building_Block_V2.Block_Types.STREET:
			mm = street_multimesh_instance.multimesh
	
	if not mm:
		return
	
	var t: Transform3D = mm.get_instance_transform(id)
	t.basis = Basis.from_scale(Vector3.ZERO)
	mm.set_instance_transform(id,t)
	
	var counter: int = 0
	for l in levels:
		for c in l.blocks:
			counter += 1
	
	counter_blocks -= 1
	#print("Counter ",counter, " | ",counter_blocks)


func destroy_b(bld:Building_Block_V2, b: CSGBox3D) -> void:
	b.queue_free()

func get_score(score: int) -> void:
	self.score += score
