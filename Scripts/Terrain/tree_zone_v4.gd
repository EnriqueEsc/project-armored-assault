extends Node3D
class_name Tree_Zone_V4

@export var tree_mesh: Mesh
@export var tree_spacing: float = 1.0
var tree_bounds: AABB
var has_tree_bounds: bool = false

var multimesh_instance_dictionary: Dictionary = {}

var tree_points: PackedVector3Array = PackedVector3Array()
var tree_state: PackedByteArray = PackedByteArray()

var tree_list: Dictionary = {}
var multimesh: MultiMesh


var active_count: int = 0

var material: ShaderMaterial = null

var tree_indexes: Array = []

@export var neighbor_radius: float = 1.5
@export var max_burnt_neighbors: int = 4

var density: float = 1.0

var tree_spatial_grid: Dictionary = {}
var folliage_type: PackedByteArray = PackedByteArray()

var geometrical_position: Vector3 = Vector3.ZERO

var flamable_mode: SettingsManager.FlamableModes = SettingsManager.FlamableModes.OnDirectFire

var occlusion_node: TerrainChunkOccluder = TerrainChunkOccluder.new(self)

var texture: Texture2D = null

var zones: Array = []

var show_visual_fire: bool = true

var max_active_fire: int = 1
var current_active_fire: int = 0

func _ready() -> void:
	
	if tree_points.size() < 1:
		if occlusion_node:
			occlusion_node.queue_free()
		queue_free()
	
	#print("SEXOOOOOOOO VIVO")
	flamable_mode = Settings_Manager.INSTANCE.flamable_mode
	var aux = float(Settings_Manager.INSTANCE.folliage_density)
	density = aux/100.0
	
	show_visual_fire = flamable_mode != Settings_Manager.FlamableModes.Invisible
	
	max_active_fire = Settings_Manager.INSTANCE.max_active_fire
	#if occlusion_node:
	#	get_tree().current_scene.call_deferred("add_child",occlusion_node)
	add_to_group("tree_zones")
	
	tree_spatial_grid.clear()
	
	
	#multimesh_instance = MultiMeshInstance3D.new()
	#call_deferred("add_child",multimesh_instance)
	
	#multimesh_instance.call_deferred("set_global_position",collision.global_position)
	#multimesh_instance.call_deferred("set_global_rotation",collision.global_rotation)
	
	#body_entered.connect(_on_body_entered)
	#body_exited.connect(_on_body_exit)
	#area_entered.connect(_on_area_entered)
	#area_exited.connect(_on_area_exit)
	'''
	tree_points.clear()
	for i in 30:
		var factor: float = 2.0
		var randx = randf_range(global_position.x - factor, global_position.x + factor)
		var randz = randf_range(global_position.z - factor, global_position.z + factor)
		var pos = Vector3(randx,global_position.y,randz)
		tree_points.append(pos)
	'''
	init_grid.call_deferred()
	
	set_neighbors()


func init_grid() -> void:
	
	if tree_points.size() < 1:
		if occlusion_node:
			occlusion_node.queue_free()
		queue_free()
	
	material = Settings_Manager.INSTANCE.Folliage_Shader_Material.duplicate()
	

	#multimesh = MultiMesh.new()
	#multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	#multimesh.instance_count = tree_points.size()
	
	#tree_grid.resize(col_size_x)
	
	var new_size: int = int(tree_points.size() * density)
	
	var aux_points: PackedVector3Array = PackedVector3Array()
	var aux_indexes: Array = []
	var aux_types: PackedByteArray = PackedByteArray()
	#aux_points.resize(new_size)
	
	#var aux: int = 0
	
	for i in range(new_size):
		var index: int = mini(int(float(i)*tree_points.size()/new_size),tree_points.size()-1)
		aux_points.append(tree_points[index])
		aux_indexes.append(tree_indexes[index])
		aux_types.append(folliage_type[index])
		
		
		#i = aux
	
	#tree_points = aux_points.duplicate()
	#tree_points.resize(new_size)
	#tree_indexes.resize(new_size)
	
	tree_points = aux_points
	tree_indexes = aux_indexes
	folliage_type = aux_types
	
	#multimesh.instance_count = tree_points.size()
	
	var type_counter: Dictionary = {}
	
	for type in folliage_type:
		type_counter[type] = type_counter.get(type,0)+1
	
	for type in type_counter:
		if not multimesh_instance_dictionary.has(type):
			create_multimesh_instance(type)
		var data: Dictionary = multimesh_instance_dictionary[type]
		var mm: MultiMesh = data["multimesh"]
		
		mm.instance_count = type_counter[type]
		data["tree_indexes"].clear()
	
	for i in range(tree_points.size()):
		tree_state.append(1)
		#var pos = tree_points[i]

		var type: int = folliage_type[i]
		
		var data: Dictionary = multimesh_instance_dictionary[type]
		var mm: MultiMesh = data["multimesh"]
		var indexes: Array = data["tree_indexes"]
		var local_index: int = indexes.size()
		indexes.append(i)
		
		#mm.instance_count = indexes.size()
		var transform: Transform3D = Transform3D.IDENTITY
		transform = transform.rotated(Vector3.UP, randf_range(0.0, TAU))
		transform.origin = tree_points[i]
		
		mm.set_instance_transform(local_index,transform)
		var tree: Dictionary = {
			"id": i,
			"position": to_global(transform.origin),
			"is_destroyed": false,
			"is_burning": false,
			"neighbors": []
		}
		#tree.got_destroyed.connect(destroy_tree)
		#tree.got_burnt.connect(burn_tree)
		if not tree_list.has(i):
			tree_list[i] = {}
		tree_list[i] = tree
		
		if not has_tree_bounds:
			tree_bounds = AABB(tree_list[i]["position"], Vector3.ZERO)
			has_tree_bounds = true
		else:
			tree_bounds = tree_bounds.expand(tree_list[i]["position"])
		
		var cell = get_tree_cell(tree_list[i]["position"])
		if not tree_spatial_grid.has(cell):
			tree_spatial_grid[cell] = []
		tree_spatial_grid[cell].append(tree)
		#print("[",x,"][",z,"]"," ",tree_grid[x][z])
	
	active_count = tree_points.size()
	#multimesh_instance.multimesh = multimesh

func modify_points(indexes: PackedInt32Array) -> void:
	for i in range(indexes.size()):
		var global_index = indexes[i]
		var local_index = tree_indexes.find(global_index)
		if local_index >= tree_list.size():
			continue
		if local_index == -1:
			continue
		if tree_state[local_index] == 0:
			continue
		tree_state[local_index] = 0
		#tree_list[local_index].hp = 0
		tree_list[local_index]["is_destroyed"] = true
		#tree_list[local_index].discarded = true
		#print("Destroy1 ",local_index)
		destroy_tree(local_index)

func take_explosion(pos: Vector3, blast_rad: float, blast_damage: float) -> void:
	var closest_tree: Tree_data = null
	var min_distance: float = INF
	for v in tree_list:
		if (not v["is_destroyed"]) and v["position"].distance_squared_to(pos) < min_distance:
			closest_tree = v
			min_distance = v.distance_squared_to(pos)
	if closest_tree:
		#print( pos," | ",closest_tree.position)
		#closest_tree.got_destroyed.emit(closest_tree.id)
		if closest_tree.is_destroyed:
			return
		blast_damage = 10
		var fire: bool = flamable_mode == Settings_Manager.FlamableModes.All
		#closest_tree.take_damage(int(blast_damage),fire)

func destroy_tree(id: int, free_empty_zone: bool = true) -> void:
	
	if not tree_list.has(id):
		return
	tree_list[id]["is_destroyed"] = true
	
	var type: int = folliage_type[id]
	
	if not multimesh_instance_dictionary.has(type):
		return
	
	var data: Dictionary = multimesh_instance_dictionary[type]
	var mm: MultiMesh = data["multimesh"]
	var indexes: Array = data["tree_indexes"]
	var local_index: int = indexes.find(id)
	
	if local_index < 0:
		return
	
	#var mm: MultiMesh = multimesh_instance.multimesh
	var t: Transform3D = mm.get_instance_transform(local_index)
	t.basis = Basis.from_scale(Vector3.ZERO)
	mm.set_instance_transform(local_index,t)
	#print("Destroy2 ",id," ",mm.get_instance_transform(id).basis)
	active_count -= 1
	if active_count <= 0 and free_empty_zone:
		if occlusion_node:
			occlusion_node.queue_free()
		queue_free()

func burn_tree(damage: int, id: int) -> void:
	#return
	if flamable_mode == Settings_Manager.FlamableModes.Disabled:
		return
	if damage <= 0 or not tree_list.has(id):
		return
	if current_active_fire >= max_active_fire:
		return
	
	
	damage /= 2
	
	#print("SEXO ",damage)
	
	#var id: int = pos.x
	
	var source: Dictionary = tree_list[id]
	
	if source["is_destroyed"] or source["is_burning"]:
		return
	
	source["is_burning"] = true
	current_active_fire += 1
	
	destroy_tree(id, false)
	
	var affected_trees: Array[Dictionary] = []
	
	for neighbor in source["neighbors"]:
		var zone_object: Object = instance_from_id(neighbor["zone_id"])
		if not is_instance_valid(zone_object):
			continue
		var zone: Tree_Zone_V4 = zone_object as Tree_Zone_V4
		var neighbor_id: int = neighbor["id"]
		
		if not is_instance_valid(zone) or zone.is_queued_for_deletion():
			continue
		
		if not zone.tree_list.has(neighbor_id):
			continue
		
		var tree: Dictionary = zone.tree_list[neighbor_id]
		
		if tree["is_destroyed"] or tree["is_burning"]:
			continue
		affected_trees.append(neighbor)
		
		if affected_trees.size() >= max_burnt_neighbors:
			break
	var fire = Effects_Manager.INSTANCE.fire_from_pool(source["position"]) if show_visual_fire else null

	if fire:
		await get_tree().create_timer(fire.lifetime / 2.0).timeout
	else:
		await get_tree().create_timer(1.5).timeout
	
	current_active_fire -= 1
	if current_active_fire < 0:
		current_active_fire = 0
	
	for neighbor in affected_trees:
		var zone_object: Object = instance_from_id(neighbor["zone_id"])
		if not is_instance_valid(zone_object):
			continue
		var zone: Tree_Zone_V4 = zone_object as Tree_Zone_V4
		var neighbor_id: int = neighbor["id"]
		if not is_instance_valid(zone) or zone.is_queued_for_deletion():
			continue
		
		zone.burn_tree(damage, neighbor_id)
	if active_count <= 0:
		if occlusion_node:
			occlusion_node.queue_free()
		queue_free()
 

func set_neighbors():
	
	for i in 60:
		await get_tree().process_frame
	
	zones = get_tree().get_nodes_in_group("tree_zones")
	
	for id in tree_list:
		tree_list[id]["neighbors"] = get_neighbors(id)
		#print(tree_list[id]["neighbors"])

func get_neighbors(id: int) -> Array[Dictionary]:
	
	var res: Array[Dictionary] = []
	
	if not tree_list.has(id):
		return res
	
	var source: Dictionary = tree_list[id]
	var source_pos: Vector3 = source["position"]
	var radius_squared: float = neighbor_radius * neighbor_radius
	
	for zone in zones:
		if not is_instance_valid(zone):
			continue
		
		if not zone.has_tree_bounds:
			continue
		
		var bounds: AABB = zone.tree_bounds
		var closest_point: Vector3 = Vector3(clampf(source_pos.x, bounds.position.x, bounds.end.x),clampf(source_pos.y, bounds.position.y, bounds.end.y),clampf(source_pos.z, bounds.position.z, bounds.end.z))
		
		if closest_point.distance_squared_to(source_pos) > radius_squared:
			continue
		
		var center_cell: Vector2i = zone.get_tree_cell(source_pos)
		var cell_radius: int = ceili(neighbor_radius / zone.neighbor_radius)
		
		for x in range(-cell_radius,cell_radius + 1):
			for z in range(-cell_radius,cell_radius + 1):
				var cell: Vector2i = center_cell + Vector2i(x,z)
				if not zone.tree_spatial_grid.has(cell):
					continue
				for neighbor in zone.tree_spatial_grid[cell]:
					var neighbor_id: int = neighbor["id"]
					
					if zone == self and neighbor_id == id:
						continue
					if neighbor["is_destroyed"]:
						continue
					if neighbor["position"].distance_squared_to(source_pos) > radius_squared:
						continue
					res.append({
						"zone_id": zone.get_instance_id(),
						"id": neighbor_id
					})
	
	return res


func get_tree_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x/neighbor_radius),floori(pos.z/neighbor_radius))

func create_multimesh_instance(type: int) -> void:
	if multimesh_instance_dictionary.has(type):
		return
	var mm_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	var mm: MultiMesh = MultiMesh.new()
	var model = null
	var local_material: ShaderMaterial = material.duplicate() as ShaderMaterial
	
	if type == 0:
		
		model = load("res://Meshes/Grass.tres")
		model = model as ArrayMesh
		#model = QuadMesh.new()
		tree_mesh = model
		
		texture = load("res://Models/Test/Grass_Grass.png")
		texture = texture as Texture2D
	else:
		
		model = load("res://Meshes/Tree.tres")
		model = model as ArrayMesh
		
		tree_mesh = model
		
		texture = load("res://Models/Test/Tree_Tree.png")
		texture = texture as Texture2D
	
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tree_mesh.duplicate()
	
	if local_material:
		if texture:
			local_material.set_shader_parameter("albedo_texture", texture)
		mm.mesh.surface_set_material(0,local_material)
	
	mm_instance.multimesh = mm
	call_deferred("add_child",mm_instance)
	
	#add_child(mm_instance)
	
	multimesh_instance_dictionary[type] = {"instance": mm_instance,
	"multimesh": mm,
	"tree_indexes":[]}
	
