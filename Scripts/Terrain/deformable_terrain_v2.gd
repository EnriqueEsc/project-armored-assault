extends StaticBody3D
class_name Deformable_Terrain_V2


var mesh_instance: MeshInstance3D = null
var vertex_chunks: Dictionary = {}
var chunks: Array[DeformableChunk] = []
var navigation: NavRegion = null

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
var recalculate_collision_timer: float = 0.0


var update_visual_next_tick: bool = false
@export var recalculate_visual_tick: float = 0.1
var recalculate_visual_timer: float = 0.0


enum DeformationMode{None,VisualOnly,All}
@export var deformation_mode: DeformationMode = DeformationMode.All
@export var max_deformation_in_runtime: float = 1.0

@export var deformation_treshold: float = 5

var image_buffer: Image = null
var texture_buffer: ImageTexture = null
var buffer_width: int = 1024
var buffer_height: int = 0

@export var use_shader: bool = true
var vertex_map: Dictionary = {}
@export var vertex_map_accuracy: float = 0.001

var spatial_grid: Dictionary = {}
@export var spatial_grid_cell_size: float = 1.0

var modified_indexes: Array[int] = []
var indexes_per_tick: int = 15

var vertex_faces: Dictionary = {}

@export var chunk_size: Vector2 = Vector2.ONE * 20

func visual_process(delta: float) -> void:
	
	if not update_visual_next_tick:
			return
	recalculate_visual_timer += delta
	if recalculate_visual_timer > recalculate_visual_tick:
		recalculate_visual_timer = 0.0
		if update_visual_next_tick:
			update_visuals()
			update_visual_next_tick = false

func collision_process(delta: float) -> void:
	
	if not update_collision_next_tick:
			return
	recalculate_collision_timer += delta
	if recalculate_collision_timer > recalculate_collision_tick:
		recalculate_collision_timer = 0.0
		if update_collision_next_tick:
			update_collisions()
			update_collision_next_tick = false

func _process(delta: float) -> void:
	visual_process(delta)
	collision_process(delta)

func _ready() -> void:
	generate()
	recalculate_visual_timer = recalculate_visual_tick
	recalculate_collision_timer = recalculate_collision_tick

func generate() -> void:
	get_visuals_from_existing_mesh()
	generate_visuals()
	generate_spatial_grid()
	generate_vertex_map()
	generate_collisions()
	generate_navmesh()
	print("COSO COSO", vertex_map.size(), " ",spatial_grid.size()," ",vertex_faces.size())
	

func generate_spatial_grid() -> void:
	spatial_grid.clear()
	
	for i in range(vertices.size()):
		var aux = get_cell_coords(vertices[i])
		if not spatial_grid.has(aux):
			spatial_grid[aux] = PackedInt32Array()
		spatial_grid[aux].append(i)

func generate_vertex_map() -> void:
	vertex_map.clear()
	
	for i in range(vertices.size()):
		var v = vertices[i]
		var aux = Vector2(snapped(v.x,vertex_map_accuracy),snapped(v.z,vertex_map_accuracy))
		
		if not vertex_map.has(aux):
			vertex_map[aux] = []
		vertex_map[aux].append(i)
	

func generate_navmesh() -> void:
	
	navigation = NavRegion.new()
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_max_climb = 0.3
	nav_mesh.geometry_collision_mask = 2
	
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	navigation.navigation_mesh = nav_mesh
	
	get_tree().current_scene.call_deferred("add_child",navigation)
	call_deferred("reparent",navigation)
	navigation.call_deferred("bake_navigation_mesh",true)
	


func get_visuals_from_existing_mesh() -> void:
	for c in get_children():
		if c is MeshInstance3D:
			mesh_instance = c
			#c.queue_free()
	
	if not mesh_instance:
		return
	
	print("MESH INSTANCE FOUND")
	
	vertices.clear()
	indexes.clear()
	uvs.clear()
	normals.clear()
	min_max_height.clear()
	
	var mesh_array = mesh_instance.mesh as ArrayMesh
	
	if not mesh_array:
		mesh_instance = null
		return
	
	var aux = mesh_array.surface_get_arrays(0)
	
	vertices = aux[Mesh.ARRAY_VERTEX]
	indexes = aux[Mesh.ARRAY_INDEX]
	uvs = aux[Mesh.ARRAY_TEX_UV] 
	normals = aux[Mesh.ARRAY_NORMAL]
	
	
	var original_transform = mesh_instance.transform
	
	for i in range(vertices.size()):
		vertices[i] = original_transform * vertices[i]
	
	if not normals.is_empty():
		
		for i in range(normals.size()):
			normals[i] = (original_transform.basis * normals[i]).normalized()
	
	mesh_instance.scale = Vector3.ONE
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	if mat:
		mat.albedo_texture = terrain_texture
		#mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = mat
	
	for v in vertices:
		#min_max_height.append(Vector2(v.y-max_deformation_in_runtime,v.y+max_deformation_in_runtime))
		min_max_height.append(Vector2(v.y-max_deformation_in_runtime,0.0))
	

	


func generate_visuals() -> void:
	
	if mesh_instance:
		create_vertex_buffer()
		var material = ShaderMaterial.new()
		material.shader = load("res://Shaders/deformation_test.gdshader")
		material.set_shader_parameter("buffer", texture_buffer)
		material.set_shader_parameter("terrain_texture", terrain_texture)
		mesh_instance.material_override = material
		return
	
	vertices.clear()
	indexes.clear()
	uvs.clear()
	normals.clear()
	min_max_height.clear()
	
	
	for z in subdivisions.y + 1:
		var z_ratio = float(z) / subdivisions.y
		for x in subdivisions.x + 1:
			var x_ratio = float(x) / subdivisions.x
			#var pos: Vector3 = Vector3((x_ratio - 0.5) * size.x,randf_range(-1,1),(z_ratio - 0.5) * size.y)
			var pos: Vector3 = Vector3((x_ratio - 0.5) * size.x,0.0,(z_ratio - 0.5) * size.y)
			#min_max_height.append(Vector2(pos.y-max_deformation_in_runtime,pos.y+max_deformation_in_runtime))
			min_max_height.append(Vector2(pos.y-max_deformation_in_runtime,0.0))
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
	var material
	
	use_shader = deformation_mode != DeformationMode.None
	
	if use_shader:
		material = ShaderMaterial.new()
		var shader = load("res://Shaders/deformation_test.gdshader")
		material.shader = shader
		#material.albedo_texture = terrain_texture
		
		
		create_vertex_buffer()
		
		material.set_shader_parameter("buffer",texture_buffer)
		material.set_shader_parameter("terrain_texture", terrain_texture)
	else:
		material = StandardMaterial3D.new()
		material.albedo_texture = terrain_texture
	mesh_instance.material_override = material
	
	call_deferred("add_child", mesh_instance)


func update() -> void:
	update_visuals()
	#update_collisions()

func update_visuals() -> void:
	if use_shader:
		_update_texture_vram()
		
		if deformation_mode != DeformationMode.All:
			return
		
		update_collision_next_tick = true
		return
	
	
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
	
	for i in modified_indexes:
		if not vertex_chunks.has(i):
			continue
		for chunk in vertex_chunks[i]:
			chunk.modify_vertex(i)
	modified_indexes.clear()
	
	for c in chunks:
		if not c.modified_indexes.is_empty():
			c.update_collision(vertices)
	return
	


func generate_collisions() -> void:
	chunks.clear()
	vertex_chunks.clear()
	
	
	var chunk_data: Dictionary = split_mesh_to_chunks()
	
	for coords in chunk_data:
		var data: Dictionary = chunk_data[coords]
		var chunk = DeformableChunk.new()
		chunk.name = "Chunk_%d_%d" % [coords.x, coords.y]
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(data["faces"])
		chunk.shape = shape
		chunk.vertex_faces = data["vertex_faces"]
		
		chunks.append(chunk)
		
		for global_index in chunk.vertex_faces:
			if not vertex_chunks.has(global_index):
				vertex_chunks[global_index] = []
			vertex_chunks[global_index].append(chunk)
		
		call_deferred("add_child",chunk)
	
	return
	
	
	'''
	var shape = ConcavePolygonShape3D.new()
	var faces = PackedVector3Array()
	faces.resize(indexes.size())
	
	vertex_faces.clear()
	
	for i in range(indexes.size()):
		var index: int = indexes[i]
		faces[i] = vertices[index]
		
		if not vertex_faces.has(index):
			vertex_faces[index] = []
		
		vertex_faces[index].append(i)
		
	shape.set_faces(faces)
	
	var col = CollisionShape3D.new()
	collision_layer = 3
	col.shape = shape
	
	#call_deferred("add_child", col)
	'''
	
	
	


func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	
	if deformation_mode == DeformationMode.None:
		return
	
	if damage <= deformation_treshold:
		return
	
	var closest_index: int = find_closest_vertex_to_point(impact_point)
	deform_terrain_by_index(closest_index)


func take_explosion(damage: int,source: Vehicle_Rigid,impact_point: Vector3,radius: float) -> void:
	
	if deformation_mode == DeformationMode.None:
		return
	
	if damage <= deformation_treshold:
		return
	
	var local_point = to_local(impact_point)
	var radius_squared = radius * radius
	var rad: Vector3 = Vector3.ONE * radius
	var min_cell: Vector3i = get_cell_coords(local_point - rad)
	var max_cell: Vector3i = get_cell_coords(local_point + rad)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			for z in range(min_cell.z, max_cell.z + 1):
				var cell: Vector3i = Vector3i(x,y,z)
				
				if not spatial_grid.has(cell):
					continue
				
				var cell_indexes: PackedInt32Array = spatial_grid[cell]
				for index in cell_indexes:
					if vertices[index].distance_squared_to(local_point) <= radius_squared:
						deform_terrain_by_index(index,damage)


func deform_terrain_by_index(index: int, damage: float = 1) -> void:
	if deformation_mode == DeformationMode.None:
		return
	if index < 0 or index >= vertices.size():
		return
		
	var target = vertices[index]
	
	var new_height: float = vertices[index].y
	
	
	var factor = - 1.0
	factor *= (float(damage) * randf_range(0.6,1.4))
	
	new_height += factor
	
	if is_equal_approx(new_height, vertices[index].y):
		return
	#print("NEW ", new_height < vertices[index].y," ",vertices[index].y," ",new_height)
	
	new_height = clampf(new_height,min_max_height[index].x,min_max_height[index].y)
	
	if new_height < min_max_height[index].x or new_height > min_max_height[index].y:
		return
	
	
	var aux = Vector2(snapped(target.x,vertex_map_accuracy), snapped(target.z,vertex_map_accuracy))
	
	if vertex_map.has(aux):
		var shared_indexes: Array = vertex_map[aux]
		for i in shared_indexes:
			vertices[i].y = new_height
			modified_indexes.append(i)
			
			if use_shader:
				var x = i % buffer_width
				var y = int(i / buffer_width)
				image_buffer.set_pixel(x, y, Color(vertices[i].x, vertices[i].y, vertices[i].z, 1.0))
	
	
	if not update_visual_next_tick:
		update_visual_next_tick = true
	#update()

func find_closest_vertex_to_point(point: Vector3) -> int:
	var local_point: Vector3 = to_local(point)
	var center: Vector3i = get_cell_coords(local_point)
	var closest_index: int = -1
	var min_dist: float = INF
	#var closest_vertex: Vector3 = Vector3.ZERO
	var search_radius: int = 1
	
	
	for x in range(center.x - search_radius,center.x + search_radius + 1):
		for y in range(center.y - search_radius,center.y + search_radius + 1):
			for z in range(center.z - search_radius,center.z + search_radius + 1):
				var cell: Vector3i = Vector3i(x,y,z)
				
				if not spatial_grid.has(cell):
					continue
				
				var cell_indexes: PackedInt32Array = spatial_grid[cell]
				for index in cell_indexes:
					var dist: float = vertices[index].distance_squared_to(local_point)
					if dist < min_dist:
						min_dist = dist
						closest_index = index
	
	'''
	for v in vertices.size():
		var dist: float = vertices[v].distance_squared_to(local_point)
		if dist < min_dist:
			min_dist = dist
			closest_index = v
	'''
	#res = vertices.find(closest_vertex)
	
	return closest_index

func _update_texture_vram():
	texture_buffer.update(image_buffer)

func create_vertex_buffer() -> void:
	var vertex_count = vertices.size()

	buffer_height = ceili(float(vertex_count) / buffer_width)

	image_buffer = Image.create(buffer_width,buffer_height,false,Image.FORMAT_RGBF)
	for i in range(vertex_count):
		var x = i % buffer_width
		var y = int(i / buffer_width)
		var vertex = vertices[i]
		image_buffer.set_pixel(x,y,Color(vertex.x, vertex.y, vertex.z, 1.0))
	texture_buffer = ImageTexture.create_from_image(image_buffer)


func get_cell_coords(pos: Vector3) -> Vector3i:
	return Vector3i(floori(pos.x / spatial_grid_cell_size),floori(pos.y / spatial_grid_cell_size),floori(pos.z / spatial_grid_cell_size))


func split_mesh_to_chunks() -> Dictionary:
	var res: Dictionary = {}
	
	var min_x: float = INF
	var min_z: float = INF
	
	for vertex in vertices:
		min_x = minf(min_x,vertex.x)
		min_z = minf(min_z,vertex.z)
	var origin = Vector2(min_x,min_z)
	
	for i in range(0,indexes.size(),3):
		var vertex_a: int = indexes[i]
		var vertex_b: int = indexes[i+1]
		var vertex_c: int = indexes[i+2]
		
		var center: Vector3 = Vector3(vertices[vertex_a]+vertices[vertex_b]+vertices[vertex_c])
		center /= 3.0
		
		var coords = Vector2i(floori((center.x - origin.x)/chunk_size.x),floori((center.z - origin.y)/chunk_size.y))
		
		if not res.has(coords):
			res[coords] = {"faces": PackedVector3Array(),"vertex_faces": {}}
			
		var chunk_data: Dictionary = res[coords]
		var faces: PackedVector3Array = chunk_data["faces"]
		var rel: Dictionary = chunk_data["vertex_faces"]
		
		var face_index: int = faces.size()
		
		faces.append(vertices[vertex_a])
		faces.append(vertices[vertex_b])
		faces.append(vertices[vertex_c])
		
		var triangle_vertices: Array[int] = [vertex_a,vertex_b,vertex_c]
		
		for x in range(3):
			var global_index: int = triangle_vertices[x]
			var local_index: int = face_index + x
			
			if not rel.has(global_index):
				rel[global_index] = []
			
			rel[global_index].append(local_index)
		
		chunk_data["faces"] = faces
		chunk_data["vertex_faces"] = rel
		res[coords] = chunk_data
	
	return res
