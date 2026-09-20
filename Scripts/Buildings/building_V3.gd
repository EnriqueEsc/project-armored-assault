extends Node3D
class_name Building_V3

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

@export var grid_map: GridMap = null
var mesh_library: MeshLibrary = null


func _ready() -> void:
	csg_active = Settings_Manager.INSTANCE.use_csg
	see_trough = Settings_Manager.INSTANCE.see_trough_buildings
	
	mesh_library = MeshLibrary.new()
	
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
	
	var item_id = 0
	var item_name = "Inner"
	mesh_library.create_item(item_id)
	mesh_library.set_item_name(item_id, item_name)
	mesh_library.set_item_mesh(item_id, pref_mesh)
	
	
	item_id = 1
	item_name = "Side"
	mesh_library.create_item(item_id)
	mesh_library.set_item_name(item_id, item_name)
	mesh_library.set_item_mesh(item_id, side_pref_mesh)
	
	item_id = 2
	item_name = "Corner"
	mesh_library.create_item(item_id)
	mesh_library.set_item_name(item_id, item_name)
	mesh_library.set_item_mesh(item_id, corner_pref_mesh)
	
	item_id = 3
	item_name = "Street"
	mesh_library.create_item(item_id)
	mesh_library.set_item_name(item_id, item_name)
	mesh_library.set_item_mesh(item_id, street_pref_mesh)
	
	
	grid_map = GridMap.new()
	add_child(grid_map)
	grid_map.position -= Vector3(0,1.0,0)
	
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
	
	grid_map.mesh_library = mesh_library
	grid_map.cell_size = Vector3.ONE
	grid_map.collision_layer = 0
	grid_map.collision_mask = 0
	
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
					#street_multimesh.set_instance_transform(street_counter, transform)
					b.id = street_counter
					b.got_destroyed.connect(destroy_block.bind(street_counter))
					street_counter += 1
					grid_map.set_cell_item(Vector3i(b.position.x,b.global_position.y,b.position.z),3,grid_map.get_orthogonal_index_from_basis(transform.basis))
				if b.block_type == b.Block_Types.INNER:
					b.id = counter
					b.got_destroyed.connect(destroy_block.bind(counter))
					counter += 1
					grid_map.set_cell_item(Vector3i(b.position.x,b.global_position.y,b.position.z),0,grid_map.get_orthogonal_index_from_basis(transform.basis))
				if b.block_type == b.Block_Types.SIDE:
					b.id = side_counter
					b.got_destroyed.connect(destroy_block.bind(side_counter))
					side_counter += 1
					grid_map.set_cell_item(Vector3i(b.position.x,b.global_position.y,b.position.z),1,grid_map.get_orthogonal_index_from_basis(transform.basis))
				if b.block_type == b.Block_Types.CORNER:
					b.id = corner_counter
					b.got_destroyed.connect(destroy_block.bind(corner_counter))
					corner_counter += 1
					grid_map.set_cell_item(Vector3i(b.position.x,b.global_position.y,b.position.z),2,grid_map.get_orthogonal_index_from_basis(transform.basis))
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
		pass


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
	grid_map.set_cell_item(Vector3i(bld.position.x,bld.global_position.y,bld.position.z), grid_map.INVALID_CELL_ITEM)
	
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
