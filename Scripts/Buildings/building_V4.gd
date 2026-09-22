extends Node3D
class_name Building_V4

var levels: Array[Building_Chunk] = []

var damage_zone: ShapeCast3D = null
var building_bounds: Vector2 = Vector2.ZERO

var effects_manager: Effects_Manager = null

var physics_tick_counter: int = 6
@export var crush_update_frequency: int = 5

var destroyed: bool = false


@export var inner_pref_mesh_instance: MeshInstance3D
@export var pref_mesh: Mesh



@export var side_pref_mesh_instance: MeshInstance3D
var side_pref_mesh: Mesh



@export var corner_pref_mesh_instance: MeshInstance3D
var corner_pref_mesh: Mesh



@export var street_pref_mesh_instance: MeshInstance3D
var street_pref_mesh: Mesh

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

var mesh_library: MeshLibrary = null

var ghost_colission: Area3D = null

var multimeshes: Dictionary = {}
var meshes_type: Dictionary = {}

func _ready() -> void:
	csg_active = Settings_Manager.INSTANCE.use_csg
	see_trough = Settings_Manager.INSTANCE.see_trough_buildings
	
	mesh_library = MeshLibrary.new()
	
	if inner_pref_mesh_instance:
		pref_mesh = inner_pref_mesh_instance.mesh
	
	if side_pref_mesh_instance:
		side_pref_mesh = side_pref_mesh_instance.mesh
	
	if corner_pref_mesh_instance:
		corner_pref_mesh = corner_pref_mesh_instance.mesh
		
	if street_pref_mesh_instance:
		street_pref_mesh = street_pref_mesh_instance.mesh
	
	var item_id = Building_Block_V2.Block_Types.INNER
	var item_name = "Inner"
	mesh_library.create_item(item_id)
	mesh_library.set_item_name(item_id, item_name)
	mesh_library.set_item_mesh(item_id, pref_mesh)
	
	var multimesh_instance = MultiMeshInstance3D.new()
	multimeshes[item_id] = multimesh_instance
	add_child(multimesh_instance)
	meshes_type[item_id] = pref_mesh
	
	if side_pref_mesh:
		item_id = Building_Block_V2.Block_Types.SIDE
		item_name = "Side"
		mesh_library.create_item(item_id)
		mesh_library.set_item_name(item_id, item_name)
		mesh_library.set_item_mesh(item_id, side_pref_mesh)
		
		multimesh_instance = MultiMeshInstance3D.new()
		multimeshes[item_id] = multimesh_instance
		add_child(multimesh_instance)
		meshes_type[item_id] = side_pref_mesh
	
	if corner_pref_mesh:
		item_id = Building_Block_V2.Block_Types.CORNER
		item_name = "Corner"
		mesh_library.create_item(item_id)
		mesh_library.set_item_name(item_id, item_name)
		mesh_library.set_item_mesh(item_id, corner_pref_mesh)
		
		multimesh_instance = MultiMeshInstance3D.new()
		multimeshes[item_id] = multimesh_instance
		add_child(multimesh_instance)
		meshes_type[item_id] = corner_pref_mesh
	
	if street_pref_mesh:
		item_id = Building_Block_V2.Block_Types.STREET
		item_name = "Street"
		mesh_library.create_item(item_id)
		mesh_library.set_item_name(item_id, item_name)
		mesh_library.set_item_mesh(item_id, street_pref_mesh)
		
		multimesh_instance = MultiMeshInstance3D.new()
		multimeshes[item_id] = multimesh_instance
		add_child(multimesh_instance)
		meshes_type[item_id] = street_pref_mesh
	
	if csg_active:
		combiner = CSGCombiner3D.new()
		add_child(combiner)
		combiner.use_collision = false
	else:
		pass
	
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
	
	player_ref = get_tree().get_first_node_in_group("Player") as Vehicle_Rigid
	
	
	init_grid()


func init_grid() -> void:
	if levels.is_empty():
		return
	
	for b in levels[0].blocks:
		if b.block_type == b.Block_Types.SIDE:
			b.block_type = b.Block_Types.STREET
	
	var block_counter: Dictionary = {}
	
	
	for t in multimeshes:
		block_counter[t] = 0
		
	for l in levels:
		for b in l.blocks:
			var t = b.block_type
			
			if not multimeshes.has(t):
				t = Building_Block_V2.Block_Types.INNER
			
			block_counter[t] += 1
	
	for t in multimeshes:
		var inst: MultiMeshInstance3D = multimeshes[t]
		
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes_type[t]
		mm.instance_count = block_counter[t]
		
		inst.multimesh = mm

	
	lowest_height = levels[0].lowest_height
	
	col_size_x = levels[0].building_bounds.x
	col_size_y = levels.size()
	col_size_z = levels[0].building_bounds.y
	
	if not csg_active:
		#print("ola")
		
		
		if see_trough:
			pref_mesh.surface_set_material(0,material)
			if side_pref_mesh:
				side_pref_mesh.surface_set_material(0,material)
			if corner_pref_mesh:
				corner_pref_mesh.surface_set_material(0,material)
			if street_pref_mesh:
				street_pref_mesh.surface_set_material(0,material)
				
		
		
	var start_x = -col_size_x * 0.5 + 1 * 0.5
	var start_y = 1 * 0.0
	var start_z = -col_size_z * 0.5 + 1 * 0.5

	var counter = 0
	var next_index: Dictionary = {}

	for type in multimeshes:
		next_index[type] = 0
		
	for c in levels:
		c.damage_zone = damage_zone
		c.building_half_extents = damage_zone.shape.size / 2.0
		c.building_max_radius = c.building_half_extents.length()
		
		for b in c.blocks:
			var type = b.block_type
			
			if not multimeshes.has(type):
				type = Building_Block_V2.Block_Types.INNER
		
			var index: int = next_index[type]
		
			var transform := Transform3D.IDENTITY
			transform.origin = Vector3(b.position.x,b.global_position.y - global_position.y,b.position.z)
		
			transform.basis = Basis.from_euler(Vector3(0.0,deg_to_rad(b.block_visual_rotation),0.0))
		
			var instance: MultiMeshInstance3D = multimeshes[type]
		
			instance.multimesh.set_instance_transform(index,transform)
		
			b.id = index
			b.got_destroyed.connect(destroy_block.bind(index))
		
			next_index[type] = index + 1
	if not csg_active:
		#print("adio")
		pass



func set_ghost_colission() -> void:
	var min_pos: Vector3 = Vector3.INF
	var max_pos: Vector3 = -Vector3.INF
	
	for l in levels:
		for b in l.blocks:
			var center = to_local(b.global_position)
			var box = b.shape as BoxShape3D
			var half_size = box.size / 2.0
			
			min_pos.x = min(min_pos.x, center.x - half_size.x)
			min_pos.y = min(min_pos.y, center.y - half_size.y)
			min_pos.z = min(min_pos.z, center.z - half_size.z)
			
			max_pos.x = max(max_pos.x, center.x + half_size.x)
			max_pos.y = max(max_pos.y, center.y + half_size.y)
			max_pos.z = max(max_pos.z, center.z + half_size.z)
	
	var ghost_size = max_pos - min_pos
	var ghost_center = (min_pos + max_pos) / 2.0
	
	ghost_colission = Area3D.new()
	
	var cube = BoxShape3D.new()
	cube.size = ghost_size
	
	var col = CollisionShape3D.new()
	col.shape = cube
	
	#damage_zone.collide_with_areas = true
	
	#col.shape.size = Vector3(building_bounds.x,5,building_bounds.y)
	
	call_deferred("add_child",ghost_colission)
	ghost_colission.call_deferred("add_child",col)
	ghost_colission.position = ghost_center
	ghost_colission.add_to_group("Terrain")


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
	
	var aux = bld.Block_Types.INNER
	#print("INTENTANDO DESTRUIR ",id," ",str(type))
	
	if bld.block_type in multimeshes:
		aux = bld.block_type
	
	mm = multimeshes[aux].multimesh
	
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
