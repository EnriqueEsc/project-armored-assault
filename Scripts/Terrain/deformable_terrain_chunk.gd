extends CollisionShape3D
class_name DeformableChunk

@export var terrain_texture: Texture2D


var vertices: PackedVector3Array = PackedVector3Array()
var indexes: PackedInt32Array = PackedInt32Array()

var last_vertices: PackedVector3Array = PackedVector3Array()

var modified_indexes: Array[int] = []
var indexes_per_tick: int = 15

var vertex_faces: Dictionary = {}
var thread_result: Array[PackedVector3Array] = [PackedVector3Array()]
var thread_id: int = -1

var deformation_mode: Deformable_Terrain.DeformationMode = Deformable_Terrain.DeformationMode.All

func generate_collisions() -> void:
	
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
	
	self.shape = shape
	

func apply_collision(shape: ConcavePolygonShape3D) -> void:
	if deformation_mode != Deformable_Terrain.DeformationMode.All:
		return
	
	self.shape = shape
	thread_id = -1

func call_update_collision(vertices: PackedVector3Array) -> void:
	if deformation_mode != Deformable_Terrain.DeformationMode.All:
		return
	
	last_vertices = vertices.duplicate()
	if thread_id != -1 or modified_indexes.is_empty():
		return
	var ind: Array[int] = modified_indexes.duplicate()
	var fac: Dictionary = vertex_faces.duplicate()
	var f: PackedVector3Array = self.shape.get_faces().duplicate()
	var ver: PackedVector3Array = PackedVector3Array()
	for i in ind:
		ver.append(last_vertices[i])
	modified_indexes.clear()
	
	thread_result[0] = PackedVector3Array()
	#var id = WorkerThreadPool.add_task(async_update_collision.bind(ver,modified_indexes,vertex_faces,f,thread_result))
	var id = WorkerThreadPool.add_task(async_update_collision.bind(ver,ind,fac,f,thread_result))
	thread_id = id

static func async_update_collision(vertices: PackedVector3Array, modified_indexes: Array[int],vertex_faces: Dictionary, faces: PackedVector3Array, result: Array) -> void:
	
	for i in range(modified_indexes.size()):
		var index: int = modified_indexes[i]
		
		if not vertex_faces.has(index):
			continue
		
		for face_index in vertex_faces[index]:
			faces[face_index] = vertices[i]
			
	result[0] = faces


func update_collision(vertices: PackedVector3Array) -> void:
	if deformation_mode != Deformable_Terrain.DeformationMode.All:
		return
	
	if modified_indexes.is_empty():
		return
	var faces: PackedVector3Array = self.shape.get_faces()
	
	for index in modified_indexes:
		if not vertex_faces.has(index):
			continue
		for face_index in vertex_faces[index]:
			faces[face_index] = vertices[index]
	var new_shape = ConcavePolygonShape3D.new()
	new_shape.set_faces(faces)
	
	self.shape = new_shape
	modified_indexes.clear()

func register_vertex(index: int, face_index: int) -> void:
	if not vertex_faces.has(index):
		vertex_faces[index] = []
	vertex_faces[index].append(face_index)

func modify_vertex(index: int) -> void:
	if vertex_faces.has(index):
		if not modified_indexes.has(index):
			modified_indexes.append(index)


func _process(delta: float) -> void:
	if deformation_mode != Deformable_Terrain.DeformationMode.All:
		return
	
	if thread_id == -1:
		return
	
	if not WorkerThreadPool.is_task_completed(thread_id):
		return
	
	WorkerThreadPool.wait_for_task_completion(thread_id)
	
	thread_id = -1
	
	var new_shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	new_shape.set_faces(thread_result[0])
	shape = new_shape
	
	if not modified_indexes.is_empty():
		call_update_collision(last_vertices)

func _exit_tree() -> void:
	if thread_id != -1:
		WorkerThreadPool.wait_for_task_completion(thread_id)
		thread_id = -1
