extends StaticBody3D
class_name Deformable_Terrain


var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null

@export var terrain_texture: Texture2D

@export var size: Vector2i = Vector2i.ONE * 100
@export var subdivisions: Vector2i = Vector2i.ONE * 100

var vertices: PackedVector3Array = PackedVector3Array()
var indexes: PackedInt32Array = PackedInt32Array()
var uvs: PackedVector2Array = PackedVector2Array()
var normals: PackedVector3Array = PackedVector3Array()
var min_max_height: PackedVector2Array = PackedVector2Array()

var update_collision_next_tick: bool = false
@export var recalculate_collision_tick: float = 1.0
var recalculate_timer: float = 0.0

var affected_buffer: Array[int] = []

enum DeformationMode{None,VisualOnly,All}
@export var deformation_mode: DeformationMode = DeformationMode.All
@export var max_deformation_in_runtime: float = 1.0

func _process(delta: float) -> void:
	if not update_collision_next_tick:
			return
	recalculate_timer += delta
	if recalculate_timer > recalculate_collision_tick:
		recalculate_timer = 0.0
		if update_collision_next_tick:
			update_collisions()
			update_collision_next_tick = false

func _ready() -> void:
	generate()
	recalculate_timer = recalculate_collision_tick

func generate() -> void:
	generate_visuals()
	generate_collisions()

func generate_visuals() -> void:
	vertices.clear()
	indexes.clear()
	uvs.clear()
	normals.clear()
	
	
	for z in subdivisions.y + 1:
		var z_ratio = float(z) / subdivisions.y
		for x in subdivisions.x + 1:
			var x_ratio = float(x) / subdivisions.x
			#var pos: Vector3 = Vector3((x_ratio - 0.5) * size.x,randf_range(-1,1),(z_ratio - 0.5) * size.y)
			var pos: Vector3 = Vector3((x_ratio - 0.5) * size.x,0.0,(z_ratio - 0.5) * size.y)
			min_max_height.append(Vector2(pos.y-max_deformation_in_runtime,pos.y+max_deformation_in_runtime))
			vertices.append(pos)
			uvs.append(Vector2(x_ratio, z_ratio))
			normals.append(Vector3.UP)
	
	
	for z in subdivisions.y:
		for x in subdivisions.x:
			var curr_vert = x + z * (subdivisions.x + 1)
			var next_vert = x + (z + 1) * (subdivisions.x + 1)
			
			var top_left = curr_vert
			var top_right = curr_vert + 1
			var bottom_left = next_vert
			var bottom_right = next_vert + 1
			
			var first_triangle = [top_left, top_right, bottom_left]
			var second_triangle = [top_right, bottom_right, bottom_left]
			
			indexes.append_array(first_triangle)
			indexes.append_array(second_triangle)
	
	
	
	var mesh_array = []
	mesh_array.resize(Mesh.ARRAY_MAX)
	mesh_array[Mesh.ARRAY_VERTEX] = vertices
	mesh_array[Mesh.ARRAY_INDEX] = indexes
	mesh_array[Mesh.ARRAY_TEX_UV] = uvs
	mesh_array[Mesh.ARRAY_NORMAL] = normals
	
	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = new_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_texture = terrain_texture
	
	mesh_instance.material_override = material
	
	call_deferred("add_child", mesh_instance)


func update() -> void:
	update_visuals()
	#update_collisions()

func update_visuals() -> void:
	var mesh = mesh_instance.mesh as ArrayMesh
	var aux = mesh.surface_get_arrays(0)
	if aux[Mesh.ARRAY_VERTEX] != vertices:
		aux[Mesh.ARRAY_VERTEX] = vertices
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, aux)
	
	if deformation_mode != DeformationMode.All:
		return
	
	update_collision_next_tick = true

func update_collisions() -> void:
	var shape = mesh_instance.mesh.create_trimesh_shape()
	if collision_shape.shape != shape:
		collision_shape.shape = shape

func generate_collisions() -> void:
	var data = mesh_instance.mesh.create_trimesh_shape()
	
	collision_shape = CollisionShape3D.new()
	
	collision_shape.shape = data
	
	call_deferred("add_child", collision_shape)


func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	var closest_index: int = find_closest_vertex_to_point(impact_point)
	deform_terrain_by_index(closest_index)


func take_explosion(damage: int, source: Vehicle_Rigid, impact_point: Vector3, radius: float) -> void:
	
	
	var radius_squared: float = radius * radius
	
	var affected_indexes: Array[int] = []
	for v in vertices:
		var dist_squared = v.distance_squared_to(impact_point)
		if dist_squared <= radius_squared:
			affected_indexes.append(vertices.find(v))
			#b.take_damage(damage, source, impact_point)
	
	for a in affected_indexes:
		deform_terrain_by_index(a)
		#call_deferred("take_damage",damage, source, impact_point)



func deform_terrain_by_index(index: int, damage: int = 1) -> void:
	if deformation_mode == DeformationMode.None:
		return
	if index < 0:
		return
	var new_height: float = vertices[index].y
	new_height -= 1.0
	new_height *= (float(damage) * randf_range(0.6,1.4))
	
	#print("NEW ", new_height < vertices[index].y," ",vertices[index].y," ",new_height)
	
	if new_height < min_max_height[index].x or new_height > min_max_height[index].y:
		return
	
	vertices[index].y = new_height
	update()

func find_closest_vertex_to_point(point: Vector3) -> int:
	var res: int = -999
	
	var min_dist: float = INF
	var closest_vertex: Vector3 = Vector3.ZERO
	
	for v in vertices:
		if v.distance_to(point) < min_dist:
			min_dist = v.distance_to(point)
			closest_vertex = v
	
	res = vertices.find(closest_vertex)
	
	return res
