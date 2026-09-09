extends Node3D
class_name Building_V2

var levels: Array[Building_Chunk] = []

var damage_zone: ShapeCast3D = null
var building_bounds: Vector2 = Vector2.ZERO

var effects_manager: Effects_Manager = null

var physics_tick_counter: int = 6
@export var crush_update_frequency: int = 5

var destroyed: bool = false

@export var pref_mesh: Mesh
var multimesh_instance: MultiMeshInstance3D = null

var multimesh: MultiMesh

signal got_destroyed

var col_size_x: int = 0
var col_size_y: int = 0
var col_size_z: int = 0

var lowest_height: float = INF

func _ready() -> void:
	multimesh_instance = MultiMeshInstance3D.new()
	add_child(multimesh_instance)
	
	for c in get_children():
		if c is Building_Chunk:
			levels.append(c)
			c.got_destroyed.connect(destroy_chunk.bind(c))
	if not levels.is_empty():
		levels[0].got_destroyed.connect(destroy_basement)
		building_bounds = levels[0].building_bounds
		set_shape_cast()
	set_physics_process(false)
	
	await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE
	
	init_grid()


func init_grid() -> void:
	if levels.is_empty():
		return
	
	lowest_height = levels[0].lowest_height
	
	col_size_x = levels[0].building_bounds.x
	col_size_y = levels.size()
	col_size_z = levels[0].building_bounds.y

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = pref_mesh
	multimesh.instance_count = col_size_x * col_size_y * col_size_z 

	var start_x = -col_size_x * 0.5 + 1 * 0.5
	var start_y = 1 * 0.0
	var start_z = -col_size_z * 0.5 + 1 * 0.5

	var counter = 0
	
	for c in levels:
		for b in c.blocks:
			var pos = Vector3(b.position.x,b.global_position.y - global_position.y,b.position.z)

			var transform = Transform3D.IDENTITY

			#transform = transform.rotated(Vector3.UP,randf_range(0.0, TAU))

			transform.origin = pos

			multimesh.set_instance_transform(counter, transform)
			b.id = counter
			b.got_destroyed.connect(destroy_block.bind(counter))
			#var tree: Tree_data = Tree_data.new(1,counter, multimesh_instance.to_global(transform.origin) ,Vector2i(x,z))
			#tree.got_destroyed.connect(destroy_tree)
			#tree.got_burnt.connect(burn_tree)
			#tree_grid[x][z] = tree
			#print("[",x,"][",z,"]"," ",tree_grid[x][z])

			counter += 1
	
	
	#active_count = counter
	multimesh_instance.multimesh = multimesh


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



func crush_below() -> void:
	damage_zone.force_shapecast_update()
	
	for i in damage_zone.get_collision_count():
		#print(i)
		var collider = damage_zone.get_collider(i)
		if collider:
			if collider.has_method("take_damage"):
				print(collider)
				collider.take_damage(10,null,collider.global_position)
			if collider.has_method("detonate"):
				collider.detonate()

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
			if b.global_position.y <= lowest_height + 0.1:
				#b.got_destroyed.emit(b)
				#b.deactivate()
				#crush_below()
				emmit_collapse_effect = true
				chunk.append(b)
		
		if chunk.is_empty():
			return
		
		for c in chunk:
			c.got_destroyed.emit(c)
			c.deactivate()
		
	crush_below()
	
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
		deactivate()
	
func destroy_basement() -> void:
	destroyed = true
	set_physics_process(true)

func deactivate() -> void:
	got_destroyed.emit()
	print("siuuuuuuu V2")
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
	

func destroy_block(bld:Building_Block_V2, id: int) -> void:
	var mm: MultiMesh = multimesh_instance.multimesh
	var t: Transform3D = mm.get_instance_transform(id)
	t.basis = Basis.from_scale(Vector3.ZERO)
	mm.set_instance_transform(id,t)

func get_score(score: int) -> void:
	self.score += score
