extends Deformable_Terrain
class_name Deformable_Terrain_V3


var is_baking_nav: bool = false
var nav_bake_in_queue: bool = false
var vertex_chunks: Dictionary = {}
var chunks: Array[DeformableChunk] = []
var visual_chunks: Array[MeshInstance3D] = []

var folliage_chunks: Array[Tree_Zone_V4] = []

@export var chunk_size: Vector2 = Vector2.ONE * 20

enum TextureMode {Classic, MeshSurface, XZ, TextureSplatting}
@export var texture_mode: TextureMode = TextureMode.MeshSurface


@export var folliage_map: Texture2D = null
var folliage_image: Image = null
#@export_range(0.0,1.0) var folliage_density: float = 1.0

@export var softness_map: Texture2D = null
var softness_values: PackedFloat32Array = PackedFloat32Array()

@export var scale_xz_uv: Vector2 = Vector2.ONE * 0.2

@export_group("Texture Splatting")
@export var textures: Array[Texture2D] = []
@export var splat_map: Texture2D = null
var mask_uv_min: Vector2 = Vector2.ZERO
var mask_uv_size: Vector2 = Vector2.ONE

var flamable_mode: SettingsManager.FlamableModes = SettingsManager.FlamableModes.OnDirectFire

var fire_tick: float = 1.0
var fire_counter: float = 0.0
var can_take_fire: bool = true

var odds_start_fire_on_explosion: int = 100

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
	fire_tick_process(delta)

func fire_tick_process(delta: float) -> void:
	if can_take_fire:
		return
	fire_counter += delta
	if fire_counter > fire_tick:
		can_take_fire = true
		return


func _ready() -> void:
	generate()
	recalculate_visual_timer = recalculate_visual_tick
	recalculate_collision_timer = recalculate_collision_tick
	
	flamable_mode = Settings_Manager.INSTANCE.flamable_mode
	
	odds_start_fire_on_explosion = Settings_Manager.INSTANCE.odds_start_fire_on_explosion

func generate() -> void:
	get_visuals_from_existing_mesh()
	
	var chunk_data: Dictionary = split_mesh_to_chunks()
	
	chunk_data = generate_visuals_new(chunk_data)
	generate_spatial_grid()
	generate_vertex_map()
	generate_collisions_new(chunk_data)
	
	
	generate_folliage_mask()
	
	generate_folliage(chunk_data)
	
	generate_navmesh()
	
	generate_softness_values()
	#print("COSO COSO", vertex_map.size(), " ",spatial_grid.size()," ",vertex_faces.size())

func generate_softness_values() -> void:
	for i in 15:
		await get_tree().process_frame
	var image: Image = null
	if not softness_map:
		image = Image.create_empty(1024,1024,false,Image.FORMAT_RGBA8)
		image.fill(Color.BLACK)
		softness_map = ImageTexture.create_from_image(image)
		var ns = NoiseTexture2D.new()
		ns.seamless = true
		ns.noise = FastNoiseLite.new()
		softness_map = ns
	else:
		image = softness_map.get_image()
	
	if not image:
		#print("AAAH NO IMAGE")
		clear_generation_data()
		return
		
	softness_values.clear()
	softness_values.resize(vertices.size())
	
	var width = image.get_width()
	var height = image.get_height()
	
	for i in range(vertices.size()):
		var uv = (uvs[i] - mask_uv_min) / mask_uv_size
		var x = clampi(roundi(uv.x * (width-1)),0,width-1)
		var y = clampi(roundi(uv.y * (height-1)),0,height-1)
		
		var value = image.get_pixel(x,y).b
		if value < 0.25:
			value = 0.0
		softness_values[i] = value
	clear_generation_data()

func clear_generation_data() -> void:
	uvs.clear()
	normals.clear()
	indexes.clear()

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
	if navigation == null:
		navigation = NavRegion.new()
		var nav_mesh: NavigationMesh = NavigationMesh.new()
		
		nav_mesh.agent_height = 2.0
		nav_mesh.agent_radius = 0.5
		nav_mesh.agent_max_climb = 0.3
		nav_mesh.geometry_collision_mask = 2
		
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		
		navigation.navigation_mesh = nav_mesh
		print("BAKING SHI CONNECTED")
		navigation.bake_finished.connect(_on_nav_bake_finished)
		
		get_tree().current_scene.call_deferred("add_child",navigation)
		call_deferred("reparent",navigation)
	call_deferred("request_nav_bake")
	

func generate_XZ_uvs() -> void:
	uvs.resize(vertices.size())
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		
		uvs[i] = Vector2(vertex.x * scale_xz_uv.x, vertex.z * scale_xz_uv.y)

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
	
	if texture_mode == TextureMode.XZ or texture_mode == TextureMode.TextureSplatting:
		generate_XZ_uvs()
	elif uvs.is_empty():
		generate_XZ_uvs()
	
	calculate_mask_uv_bounds()
	normals = aux[Mesh.ARRAY_NORMAL]
	
	var original_transform = mesh_instance.transform
	
	for i in range(vertices.size()):
		vertices[i] = original_transform * vertices[i]
	
	if not normals.is_empty():
		
		for i in range(normals.size()):
			normals[i] = (original_transform.basis * normals[i]).normalized()
	
	
	if texture_mode == TextureMode.MeshSurface:
		terrain_texture = mesh_instance.get_active_material(0).albedo_texture
	
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
	

func set_splat_material(material: ShaderMaterial) -> void:
	
	material.set_shader_parameter("texture_1",textures[0])
	material.set_shader_parameter("texture_2",textures[1])
	material.set_shader_parameter("texture_3",textures[2])
	material.set_shader_parameter("splat_map",splat_map)
	
	material.set_shader_parameter("mask_uv_min",mask_uv_min)
	material.set_shader_parameter("mask_uv_size",mask_uv_size)

func calculate_mask_uv_bounds() -> void:
	if uvs.is_empty():
		return
	
	var uv_min: Vector2 = Vector2(INF,INF)
	var uv_max: Vector2 = Vector2(-INF,-INF)
	
	for uv in uvs:
		uv_min.x = minf(uv_min.x, uv.x)
		uv_min.y = minf(uv_min.y, uv.y)
		
		uv_max.x = maxf(uv_max.x, uv.x)
		uv_max.y = maxf(uv_max.y, uv.y)
	mask_uv_min = uv_min
	mask_uv_size = uv_max - uv_min
	
	mask_uv_size.x = maxf(mask_uv_size.x, 0.001)
	mask_uv_size.y = maxf(mask_uv_size.y, 0.001)

func generate_visuals_new(chunk_data: Dictionary) -> Dictionary:
	
	if mesh_instance:
		create_vertex_buffer()
		var material = ShaderMaterial.new()
		if texture_mode == TextureMode.TextureSplatting:
			material.shader = load("res://Shaders/deformation_v3.gdshader")
			material.set_shader_parameter("use_deformation",deformation_mode != DeformationMode.None)
			set_splat_material(material)
		else:
			material.shader = load("res://Shaders/deformation_v2.gdshader")
		material.set_shader_parameter("buffer", texture_buffer)
		material.set_shader_parameter("terrain_texture", terrain_texture)
		material.set_shader_parameter("buffer_width",buffer_width)
		
		
		#var chunk_data = split_mesh_to_chunks()
		generate_visual_chunks(chunk_data,material)
		mesh_instance.queue_free()
		mesh_instance = null
		return chunk_data
	
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
			#uvs.append(Vector2(x_ratio, z_ratio))
			#uvs.append(Vector2(x_ratio * size.x * scale_xz_uv.x,z_ratio * size.y * scale_xz_uv.y))
			
			if texture_mode == TextureMode.XZ or texture_mode == TextureMode.TextureSplatting:
				uvs.append(Vector2(x_ratio * size.x * scale_xz_uv.x, z_ratio * size.y * scale_xz_uv.y))
			else:
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
	
	var material
	
	
	use_shader = deformation_mode != DeformationMode.None or texture_mode == TextureMode.TextureSplatting
	
	if use_shader:
		material = ShaderMaterial.new()
		var shader: Shader = null
		
		if texture_mode == TextureMode.TextureSplatting:
			calculate_mask_uv_bounds()
			shader = load("res://Shaders/deformation_v3.gdshader")
		else:
			shader = load("res://Shaders/deformation_v2.gdshader")
		material.shader = shader
		#material.albedo_texture = terrain_texture
		
		
		create_vertex_buffer()
		
		material.set_shader_parameter("buffer",texture_buffer)
		material.set_shader_parameter("terrain_texture", terrain_texture)
		material.set_shader_parameter("buffer_width",buffer_width)
		
		if texture_mode == TextureMode.TextureSplatting:
			material.set_shader_parameter("use_deformation",deformation_mode != DeformationMode.None)
			set_splat_material(material)
	else:
		material = StandardMaterial3D.new()
		material.albedo_texture = terrain_texture
	#var chunk_data = split_mesh_to_chunks()
	
	chunk_data = split_mesh_to_chunks()
	
	
	generate_visual_chunks(chunk_data,material)
	return chunk_data


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


func generate_visual_chunks(chunk_data: Dictionary, material: Material) -> void:
	visual_chunks.clear()
	
	for coords in chunk_data:
		var data: Dictionary = chunk_data[coords]
		
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		
		arrays[Mesh.ARRAY_VERTEX] = data["vertices"]
		arrays[Mesh.ARRAY_INDEX] = data["indexes"]
		arrays[Mesh.ARRAY_TEX_UV] = data["uvs"]
		arrays[Mesh.ARRAY_TEX_UV2] = data["uv2s"]
		arrays[Mesh.ARRAY_NORMAL] = data["normals"]
		
		var new_mesh = ArrayMesh.new()
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		
		var instance = MeshInstance3D.new()
		instance.name = "Visual_%d_%d" % [coords.x, coords.y]
		instance.mesh = new_mesh
		instance.material_override = material.duplicate()
		
		visual_chunks.append(instance)
		call_deferred("add_child",instance)
		var occluder: TerrainChunkOccluder = TerrainChunkOccluder.new(instance)
		call_deferred("add_child",occluder)
		
		
		var aabb: AABB = instance.mesh.get_aabb()
		#var center_local: Vector3 = Vector3(aabb.get_center().x,0,aabb.get_center().z)
		var center_local: Vector3 = aabb.get_center()
		center_local.y = 0.0
		var center_global: Vector3 = global_transform * center_local
		
		occluder.geometric_center = center_global
		var factor = sqrt(chunk_size.length() / Vector2(5, 5).length())
		occluder.max_render_distance = 1500 * factor
		occluder.max_process_distance = occluder.max_render_distance * 2
		occluder.occlusion_tick = 0.1
		
		#print("COSO ",occluder.geometric_center)

func update_collisions() -> void:
	var affected_chunks: Dictionary = {}
	var modified_indexes_local = modified_indexes.duplicate()
	modified_indexes.clear()
	
	for i in modified_indexes_local:
		if not vertex_chunks.has(i):
			continue
		for chunk in vertex_chunks[i]:
			chunk.modify_vertex(i)
			affected_chunks[chunk] = true
	
	for c in affected_chunks:
		c.call_update_collision(vertices)
	
	for f in folliage_chunks:
		if not is_instance_valid(f):
			continue
		f.modify_points(modified_indexes_local)
	


func generate_collisions_new(chunk_data: Dictionary) -> void:
	chunks.clear()
	vertex_chunks.clear()
	
	collision_layer = 3
	
	#var chunk_data: Dictionary = split_mesh_to_chunks()
	
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
		
		#chunk.collision_layer = 2
		call_deferred("add_child",chunk)
		chunk.deformation_mode = deformation_mode
	
		var occluder: TerrainChunkOccluder = TerrainChunkOccluder.new(chunk)
		call_deferred("add_child",occluder)
		
		
		var aabb: AABB = AABB()
		var faces: PackedVector3Array = data["faces"]
		
		if not faces.is_empty():
			aabb = AABB(faces[0],Vector3.ZERO)
			
			for vertex in faces:
				aabb = aabb.expand(vertex)
		
		#var center_local: Vector3 = Vector3(aabb.get_center().x,0,aabb.get_center().z)
		var center_local: Vector3 = aabb.get_center()
		var center_global: Vector3 = global_transform * center_local
		
		occluder.geometric_center = center_global
		var factor = sqrt(chunk_size.length() / Vector2(5, 5).length())
		occluder.max_render_distance = 2000 * factor
		occluder.max_process_distance = occluder.max_render_distance
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
	
	
	


func generate_folliage_mask() -> void:
	for i in 15:
		await get_tree().process_frame
	
	if not folliage_map:
		folliage_image = null
		return
	
	folliage_image = folliage_map.get_image()
	
	if not folliage_image:
		return

func get_folliage_values(uv: Vector2) -> Vector2:
	if not folliage_image:
		return Vector2.ZERO
	
	var mask_uv: Vector2 = (uv - mask_uv_min) / mask_uv_size
	
	var x: int = clampi(roundi(mask_uv.x * (folliage_image.get_width() - 1)),0,folliage_image.get_width() - 1)
	var y: int = clampi(roundi(mask_uv.y * (folliage_image.get_height() - 1)),0,folliage_image.get_height() - 1)
	
	var aux: Vector2 = Vector2.ZERO
	
	var pixel: Color = folliage_image.get_pixel(x,y)
	var channels: Array[float] = [pixel.r,pixel.g,pixel.b]
	var channel: int = 0
	
	for i in range(channels.size()):
		if channels[i] > channels[channel]:
			channel = i
	
	#var res = 1.0 - folliage_image.get_pixel(x,y).get_luminance()
	var res: float = channels[channel]
	
	if res < 0.5:
		res = 0.0
	elif res >= 0.5:
		res = 1.0
	aux = Vector2(res,channel)
	return aux

func generate_folliage(chunk_data: Dictionary) -> void:
	if Settings_Manager.INSTANCE.folliage_density <= 0:
		#print("SEXOOOOOOOO MUERTO")
		return
	for i in 15:
		await get_tree().process_frame
	folliage_chunks.clear()
	
	#var chunk_data: Dictionary = split_mesh_to_chunks()
	
	#var model = load("res://Meshes/Grass.tres")
	#model = model as ArrayMesh
	for coords in chunk_data:
		var data: Dictionary = chunk_data[coords]
		var chunk = Tree_Zone_V4.new()
		chunk.name = "Folliage_%d_%d" % [coords.x, coords.y]
		var faces = (data["faces"])
		#chunk.tree_points = data["vertices"]
		#chunk.tree_mesh = model
		#chunk.tree_indexes = data["global_indexes"]
		
		
		var points: PackedVector3Array = data["vertices"]
		var indexes: Array = data["global_indexes"]
		var chunk_uvs: PackedVector2Array = data["uvs"]
		
		var aux_points: PackedVector3Array = PackedVector3Array()
		var aux_indexes: Array = []
		var aux_types: PackedByteArray = PackedByteArray()
		
		for i in range(points.size()):
			var aux_vec: Vector2 = get_folliage_values(chunk_uvs[i])
			var value: float = aux_vec.x
			var type: int = int(aux_vec.y)
			
			if value >= 0.5:
				aux_points.append(points[i])
				aux_indexes.append(indexes[i])
				aux_types.append(type)
				
		
		if aux_points.size() < 1:
			continue
		
		chunk.tree_points = aux_points
		chunk.tree_indexes = aux_indexes
		var f_type: PackedByteArray = PackedByteArray()
		f_type.resize(aux_points.size())
		for i in range(f_type.size()):
			f_type[i] = randi_range(0,1)
		f_type.fill(1)
		chunk.folliage_type = aux_types
		#chunk.density = folliage_density
		folliage_chunks.append(chunk)
		
		#for global_index in chunk.vertex_faces:
		#	if not vertex_chunks.has(global_index):
		#		vertex_chunks[global_index] = []
		#	vertex_chunks[global_index].append(chunk)
		
		#chunk.collision_layer = 2
		call_deferred("add_child",chunk)
		#chunk.call_deferred("set_global_position",center_global)
	
		var occluder: TerrainChunkOccluder = TerrainChunkOccluder.new(chunk)
		#return
		call_deferred("add_child",occluder)
		
		var aabb: AABB = AABB()
		
		if not faces.is_empty():
			aabb = AABB(faces[0],Vector3.ZERO)
			
			for vertex in faces:
				aabb = aabb.expand(vertex)
		
		var center_local: Vector3 = aabb.get_center()
		#center_local.y = 0.0
		var center_global: Vector3 = global_transform * center_local
		
		occluder.geometric_center = center_global
		var factor = sqrt(chunk_size.length() / Vector2(5, 5).length())
		occluder.max_render_distance = 1500 * factor
		occluder.max_process_distance = occluder.max_render_distance
		chunk.occlusion_node = occluder
		chunk.geometrical_position = center_global

func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	
	if deformation_mode == DeformationMode.None:
		return
	
	if damage <= deformation_treshold:
		return
	
	var closest_index: int = find_closest_vertex_to_point(impact_point)
	deform_terrain_by_index(closest_index)


func take_explosion(damage: int,source: Vehicle_Rigid,impact_point: Vector3,radius: float, apply_fire: bool = true) -> void:
	
	
	if flamable_mode == Settings_Manager.FlamableModes.All and apply_fire:
		var odds: int = randi_range(0,100)
		if odds < odds_start_fire_on_explosion:
			take_fire(damage,impact_point,radius)
	
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
	
	if softness_values[index] < 0.25:
		return
	
	var target = vertices[index]
	
	var new_height: float = vertices[index].y
	
	
	var factor = - 1.0
	#print("SOFT ",softness_values[index])
	factor *= (float(damage) * randf_range(0.6,1.4)) * softness_values[index]
	
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
		
		var triangle: Array[int] = [vertex_a,vertex_b,vertex_c]
		
		var center: Vector3 = Vector3(vertices[vertex_a]+vertices[vertex_b]+vertices[vertex_c])
		center /= 3.0
		
		var coords = Vector2i(floori((center.x - origin.x)/chunk_size.x),floori((center.z - origin.y)/chunk_size.y))
		
		if not res.has(coords):
			res[coords] = {"faces": PackedVector3Array(),
			"vertex_faces": {},
			"vertices": PackedVector3Array(),
			"indexes": PackedInt32Array(),
			"uvs": PackedVector2Array(),
			"uv2s": PackedVector2Array(),
			"normals":PackedVector3Array(),
			"global_indexes": [],
			"vertex_map": {}
			}
			
		var data: Dictionary = res[coords]
		var face_index: int = data["faces"].size()
		
		for x in range(3):
			var global_index: int = triangle[x]
			
			data["faces"].append(vertices[global_index])
			if not data["vertex_faces"].has(global_index):
				data["vertex_faces"][global_index] = []
			data["vertex_faces"][global_index].append(face_index + x)
			
			var local_map: Dictionary = data["vertex_map"]
			
			if not local_map.has(global_index):
				var local_index: int = data["vertices"].size()
				
				local_map[global_index] = local_index
				
				data["vertices"].append(vertices[global_index])
				data["uvs"].append(uvs[global_index])
				data["uv2s"].append(Vector2(global_index,0))
				data["normals"].append(normals[global_index])
				data["global_indexes"].append(global_index)
				
			data["indexes"].append(local_map[global_index])
	
	return res


func request_nav_bake() -> void:
	if not navigation:
		return
	if is_baking_nav:
		nav_bake_in_queue = true
		return
	print("BAKING SHI")
	is_baking_nav = true
	navigation.bake_navigation_mesh(true)

func _on_nav_bake_finished() -> void:
	is_baking_nav = false
	print("FINISHED BAKING SHI")
	
	if nav_bake_in_queue:
		nav_bake_in_queue = false
		call_deferred("request_nav_bake")


func take_fire(damage: int, impact_point: Vector3, radius: float = 1.0) -> void:
	if not can_take_fire:
		return
	if folliage_chunks.is_empty():
		return
	if flamable_mode == Settings_Manager.FlamableModes.Disabled:
		return
	
	#print("SEXOOO FUEGO")
	
	can_take_fire = false
	fire_counter = 0.0
	
	var radius_squared: float = radius * radius
	var fire: bool = flamable_mode != Settings_Manager.FlamableModes.Invisible
	
	for c in folliage_chunks:
		if not is_instance_valid(c):
			continue
		var center_cell: Vector2i = c.get_tree_cell(impact_point)
		var cell_radius: int = ceili(radius / c.neighbor_radius)
		
		for x in range(-cell_radius,cell_radius+1):
			for z in range(-cell_radius,cell_radius+1):
				var cell: Vector2i = center_cell + Vector2i(x,z)
				
				if not c.tree_spatial_grid.has(cell):
					continue
				for tree in c.tree_spatial_grid[cell]:
					if tree["is_destroyed"]:
						continue
					if tree["position"].distance_squared_to(impact_point) > radius_squared:
						continue
					c.burn_tree(damage, tree["id"])


'''
func take_fire(damage: int, impact_point: Vector3, radius: float = 1.0) -> void:
	if folliage_chunks.is_empty():
		return
	var closest_zone: Tree_Zone_V4 = null
	var closest_tree: Tree_data = null
	var min_distance: float = (radius * radius)
	min_distance += (min_distance * 0.2)
	
	#min_distance = INF
	
	for zone in folliage_chunks:
		#if zone.geometrical_position.distance_squared_to(impact_point) > 2000:
		if not zone.occlusion_node.is_on_render_range(impact_point):
			continue
		for tree in zone.tree_list:
			if tree.is_destroyed:
				continue
			
			var distance: float = tree.position.distance_squared_to(impact_point)
			
			if distance < min_distance:
				min_distance = distance
				closest_tree = tree
				closest_zone = zone
				
	if closest_tree and closest_zone:
		closest_tree.take_damage(damage,true)
'''
