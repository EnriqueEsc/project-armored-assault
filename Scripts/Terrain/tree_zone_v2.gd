extends Node3D
class_name Tree_Zone_V2

@export var tree_mesh: Mesh
@export var tree_spacing: float = 1.0
@export var tree_prefab: MeshInstance3D = null


var multimesh_instance: MultiMeshInstance3D = null

var tree_points: PackedVector3Array = PackedVector3Array()
var tree_state: PackedByteArray = PackedByteArray()

var tree_list: Array[Tree_data] = []
var multimesh: MultiMesh

var col_size_x: int = 0
var col_size_z: int = 0

var vehicles_within: Array[Vehicle_Rigid] = []

var active_count: int = 0

var material: ShaderMaterial = null

var tree_indexes: Array = []

@export var neighbor_radius: float = 1.5
@export var max_burnt_neighbors: int = 4

var tree_spatial_grid: Dictionary = {}
var burn_state: PackedByteArray = PackedByteArray()

var geometrical_position: Vector3 = Vector3.ZERO

var occlusion_node: TerrainChunkOccluder = TerrainChunkOccluder.new(self)

func _ready() -> void:
	
	#if occlusion_node:
	#	get_tree().current_scene.call_deferred("add_child",occlusion_node)
	add_to_group("tree_zones")
	
	tree_spatial_grid.clear()
	burn_state.resize(tree_points.size())
	burn_state.fill(0)
	
	
	multimesh_instance = MultiMeshInstance3D.new()
	call_deferred("add_child",multimesh_instance)
	
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


func init_grid() -> void:
	
	material = Settings_Manager.INSTANCE.Folliage_Shader_Material.duplicate()
	

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	if tree_prefab:
		var albedo_texture = tree_prefab.mesh.surface_get_material(0).albedo_texture
		if albedo_texture:
			material.set_shader_parameter("albedo_texture", albedo_texture)
		multimesh.mesh = tree_prefab.mesh.duplicate()
		if material:
			multimesh.mesh.surface_set_material(0,material)
	else:
		multimesh.mesh = tree_mesh.duplicate()
		if material:
			multimesh.mesh.surface_set_material(0,material)
	multimesh.instance_count = tree_points.size()

	#tree_grid.resize(col_size_x)

	for i in range(tree_points.size()):
		tree_state.append(1)
		var pos = tree_points[i]

		var transform = Transform3D.IDENTITY

		transform = transform.rotated(Vector3.UP,randf_range(0.0, TAU))

		transform.origin = pos
			
		#var tree_global_position = to_global(pos)
		multimesh.set_instance_transform(i, transform)
		var tree: Tree_data = Tree_data.new(1,i, multimesh_instance.to_global(transform.origin) ,Vector2i(i,i))
		tree.got_destroyed.connect(destroy_tree)
		tree.got_burnt.connect(burn_tree)
		tree_list.append(tree)
		
		var cell = get_tree_cell(tree.position)
		if not tree_spatial_grid.has(cell):
			tree_spatial_grid[cell] = []
		tree_spatial_grid[cell].append(tree)
		#print("[",x,"][",z,"]"," ",tree_grid[x][z])
	
	active_count = tree_points.size()
	multimesh_instance.multimesh = multimesh

func modify_points(indexes: PackedInt32Array) -> void:
	for i in range(indexes.size()):
		var global_index = indexes[i]
		var local_index = tree_indexes.find(global_index)
		if local_index == -1:
			continue
		if tree_state[local_index] == 0:
			continue
		tree_state[local_index] = 0
		tree_list[local_index].hp = 0
		tree_list[local_index].is_destroyed = true
		destroy_tree(local_index)

func take_explosion(pos: Vector3, blast_rad: float, blast_damage: float) -> void:
	var closest_tree: Tree_data = null
	var min_distance: float = INF
	for v in tree_list:
		if v.hp > 0 and v.distance_squared_to(pos) < min_distance:
			closest_tree = v
			min_distance = v.distance_squared_to(pos)
	if closest_tree:
		#print( pos," | ",closest_tree.position)
		#closest_tree.got_destroyed.emit(closest_tree.id)
		if closest_tree.is_destroyed:
			return
		blast_damage = 10
		closest_tree.take_damage(int(blast_damage),true)

func destroy_tree(id: int) -> void:
	var mm: MultiMesh = multimesh_instance.multimesh
	var t: Transform3D = mm.get_instance_transform(id)
	t.basis = Basis.from_scale(Vector3.ZERO)
	mm.set_instance_transform(id,t)
	active_count -= 1
	if active_count <= 0:
		queue_free()

func burn_tree(damage: int, pos: Vector2i) -> void:
	if damage <= 0:
		return
	
	var local_index: int = pos.x
	if local_index < 0 or local_index >= tree_list.size():
		return
	
	if burn_state[local_index] == 1:
		return
	
	burn_state[local_index] = 1
	
	var source: Tree_data = tree_list[local_index]
	var source_cell: Vector2i = get_tree_cell(source.position)
	
	var radius_squared: float = neighbor_radius * neighbor_radius
	
	var affected_count: int = 0
	
	var zones: Array = get_tree().get_nodes_in_group("tree_zones")
	
	var affected_trees: Array[Tree_data] = []
	
	for zone in zones:
		for x in range(-1,2):
			for z in range(-1,2):
				var cell: Vector2i = zone.get_tree_cell(source.position) + Vector2i(x,z)
				if not zone.tree_spatial_grid.has(cell):
					continue
				var candidates: Array = zone.tree_spatial_grid[cell]
				
				for tree in candidates:
					if tree == source:
						continue
					
					if source.position.distance_squared_to(tree.position) > radius_squared:
						continue
					if tree.is_destroyed:
						continue
					affected_trees.append(tree)
					#tree.take_damage(damage,true)
					affected_count += 1
					
					if affected_count >= max_burnt_neighbors:
						break
				if affected_count >= max_burnt_neighbors:
					break
			if affected_count >= max_burnt_neighbors:
				break
		if affected_count >= max_burnt_neighbors:
			break
		
	var fire = Effects_Manager.INSTANCE.fire_from_pool(source.position)
	if fire:
		await get_tree().create_timer(fire.lifetime/2.0).timeout
	else:
		await get_tree().create_timer(1.5).timeout
	
	for tree in affected_trees:
		tree.take_damage(damage,true)

func get_tree_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x/neighbor_radius),floori(pos.z/neighbor_radius))
