extends StaticBody3D
class_name Deformable_Terrain


var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
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
	generate_vertex_map()
	generate_collisions()
	generate_navmesh()


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
	#var shape = mesh_instance.mesh.create_trimesh_shape()
	var shape = ConcavePolygonShape3D.new()
	var faces = PackedVector3Array()
	
	faces.resize(indexes.size())
	
	for i in range(indexes.size()):
		faces[i] = vertices[indexes[i]]
		
	shape.set_faces(faces)
	collision_shape.shape = shape
	return
	
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indexes
	
	var collision_mesh = ArrayMesh.new()
	collision_mesh.add_surface_from_arrays(	Mesh.PRIMITIVE_TRIANGLES,arrays)
	
	#var shape = collision_mesh.create_trimesh_shape()
	
	if collision_shape.shape != shape:
		collision_shape.shape = shape

func generate_collisions() -> void:
	
	var shape = ConcavePolygonShape3D.new()
	var faces = PackedVector3Array()
	faces.resize(indexes.size())
	
	for i in range(indexes.size()):
		faces[i] = vertices[indexes[i]]
		
	shape.set_faces(faces)
	
	collision_shape = CollisionShape3D.new()
	collision_layer = 3
	collision_shape.shape = shape
	
	call_deferred("add_child", collision_shape)
	
	return
	
	var data = mesh_instance.mesh.create_trimesh_shape()
	
	collision_shape = CollisionShape3D.new()
	collision_layer = 3
	
	collision_shape.shape = data
	
	call_deferred("add_child", collision_shape)



func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	if damage <= deformation_treshold:
		return
	
	var closest_index: int = find_closest_vertex_to_point(impact_point)
	deform_terrain_by_index(closest_index)


func take_explosion(damage: int,source: Vehicle_Rigid,impact_point: Vector3,radius: float) -> void:
	if damage <= deformation_treshold:
		return
	
	var local_point = to_local(impact_point)
	var radius_squared = radius * radius
	
	for i in range(vertices.size()):
		if vertices[i].distance_squared_to(local_point) <= radius_squared:
			deform_terrain_by_index(i,damage)
	
	return
	
	var vertex_spacing_x = (float(size.x) / subdivisions.x)
	var vertex_spacing_z = (float(size.y) / subdivisions.y)
	
	var center_x = roundi((local_point.x + size.x * 0.5) / vertex_spacing_x)
	var center_z = roundi((local_point.z + size.y * 0.5) / vertex_spacing_z)
	
	var range_x = ceili(radius / vertex_spacing_x)
	var range_z = ceili(radius / vertex_spacing_z)
	
	var min_x = maxi(0, center_x - range_x)
	var max_x = mini(subdivisions.x, center_x + range_x)
	
	var min_z = maxi(0, center_z - range_z)
	var max_z = mini(subdivisions.y, center_z + range_z)
	
	var row_size = subdivisions.x + 1
	
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			
			var index = x + z * row_size
			var vertex = vertices[index]
			var dist_x = vertex.x - local_point.x
			var dist_z = vertex.z - local_point.z
			var distance_squared = (dist_x * dist_x) + (dist_z * dist_z)
			
			if distance_squared > radius_squared:
				continue
				
			var distance = sqrt(distance_squared)
			var fallout = 1.0 - (distance / radius)
			
			deform_terrain_by_index(index,damage)
			#deform_terrain_by_index(index,damage * fallout)


func deform_terrain_by_index(index: int, damage: float = 1) -> void:
	if deformation_mode == DeformationMode.None:
		return
	if index < 0 or index >= vertices.size():
		return
		
	var target = vertices[index]
	
	var new_height: float = vertices[index].y
	new_height -= 1.0
	new_height *= (float(damage) * randf_range(0.6,1.4))
	
	#print("NEW ", new_height < vertices[index].y," ",vertices[index].y," ",new_height)
	
	new_height = clampf(new_height,min_max_height[index].x,min_max_height[index].y)
	
	if new_height < min_max_height[index].x or new_height > min_max_height[index].y:
		return
	
	
	var aux = Vector2(snapped(target.x,vertex_map_accuracy), snapped(target.z,vertex_map_accuracy))
	
	if vertex_map.has(aux):
		var shared_indexes: Array = vertex_map[aux]
		for i in shared_indexes:
			vertices[i].y = new_height
			
			if use_shader:
				var x = i % buffer_width
				var y = int(i / buffer_width)
				image_buffer.set_pixel(x, y, Color(vertices[i].x, vertices[i].y, vertices[i].z, 1.0))
	
	if not update_visual_next_tick:
		update_visual_next_tick = true
	#update()

func find_closest_vertex_to_point(point: Vector3) -> int:
	var closest_index: int = -1
	var min_dist: float = INF
	var local_point: Vector3 = to_local(point)
	#var closest_vertex: Vector3 = Vector3.ZERO
	
	for v in vertices.size():
		var dist: float = vertices[v].distance_squared_to(local_point)
		if dist < min_dist:
			min_dist = dist
			closest_index = v
	
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
