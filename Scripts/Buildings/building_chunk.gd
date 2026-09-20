extends StaticBody3D
class_name Building_Chunk


var blocks: Array[Building_Block_V2] = []
var key_blocks: Array[Building_Block_V2] = []

var building_bounds: Vector2 = Vector2.ZERO

var total_blocks: int = 0
var min_blocks: int = 0

@export var max_armor_points: int = 40
var armor_points: int = 40

var lowest_height = INF

var destroyed: bool = false

var destruction_sensor: ShapeCast3D

var damage_zone: ShapeCast3D = null

var building_half_extents: Vector3 = Vector3.ZERO
var building_max_radius: float = 0

var effects_manager: Effects_Manager = null

var physics_tick_counter: int = 6
@export var crush_update_frequency: int = 5

const BLOCK_SCRIPT = preload("res://Scripts/Buildings/building_block_v2.gd")

var block_matrix: Dictionary = {}
var grid_size: float = 1.0

var furthest_block_pos: Vector3 = Vector3.ZERO
var check_offset: Vector2 = Vector2.ZERO

signal got_destroyed

func _ready() -> void:
	
	max_armor_points = randi_range(1,5)
	
	for b in get_children():
		
		if b is CollisionShape3D and b.visible:
			b.set_script(BLOCK_SCRIPT)
			
			var new_block = b as Building_Block_V2
			b.initialize()
			new_block.max_armor_points = max_armor_points
			new_block.armor_points = max_armor_points
			
			new_block.got_destroyed.connect(block_destroyed)
			
			blocks.append(new_block)
			
			if new_block.global_position.y < lowest_height:
				lowest_height = new_block.global_position.y
			if abs(new_block.position.x + (new_block.shape.size.x / 0.5)) > building_bounds.x:
				building_bounds.x = abs(new_block.position.x + (new_block.shape.size.x / 0.5))
			if abs(new_block.position.z + (new_block.shape.size.z / 0.5)) > building_bounds.y:
				building_bounds.y = abs(new_block.position.z + (new_block.shape.size.z / 0.5))
				
			check_offset = Vector2(new_block.shape.size.x,new_block.shape.size.y) 
	var counter: int = 0
	var aux = Vector2i(((building_bounds/2.0)/check_offset))*2
	aux = Vector2(aux)
	#print(aux)
	for b in blocks:
		
		if b.position.x < 0 and b.position.z >= 0:
			b.block_visual_rotation = 180
		elif b.position.x >= 0 and b.position.z < 0:
			b.block_visual_rotation = 90
		elif b.position.x < 0 and b.position.z < 0:
			b.block_visual_rotation = 180
		elif b.position.x < b.position.z:
			b.block_visual_rotation = 0
		elif b.position.x > b.position.z:
			b.block_visual_rotation = 0
			
		#print((Vector2(b.position.x,b.position.z)), " ",aux," ", abs(Vector2(b.position.x,b.position.z)) == aux)
				
		if abs(b.position.x) == aux.x or abs(b.position.z) == aux.y:
			b.block_type = b.Block_Types.SIDE
				
			var on_x_edge = is_equal_approx(abs(b.position.x), aux.x)
			var on_z_edge = is_equal_approx(abs(b.position.z), aux.y)

			if on_x_edge and on_z_edge:
				b.block_type = b.Block_Types.CORNER

			elif on_x_edge:
				b.block_type = b.Block_Types.SIDE

				if b.position.x > 0:
					b.block_visual_rotation = 0
				else:
					b.block_visual_rotation = 180

			elif on_z_edge:
				b.block_type = b.Block_Types.SIDE

				if b.position.z < 0:
					b.block_visual_rotation = 90
				else:
					b.block_visual_rotation = 270
			#print("OLANO")
		
		if abs(Vector2(b.position.x,b.position.z)) == aux:
			#print("OLASI")
			b.block_type = b.Block_Types.CORNER
			if b.position.x <= 0 and b.position.z >= 0:
				b.block_visual_rotation = 270
			
		
		#if b.block_type == b.Block_Types.SIDE:
			#print((Vector2(b.position.x,b.position.z)), " ",b.block_visual_rotation)
		
		if b.global_position.y == lowest_height:
			key_blocks.append(b)
			#print(counter," | ",b)
			counter += 1
	
	total_blocks = blocks.size()
	min_blocks = total_blocks/2
	
	#print("Bounds: ",building_bounds)
	#print(total_blocks," | ",blocks.size()," | ",key_blocks.size())
	#building_half_extents = damage_zone.shape.size / 2.0
	building_max_radius = building_half_extents.length()
	#global_position.y = 10
	
	set_physics_process(false)
	
	await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE


func calculate_closest_block(damage:int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	var closest_block: CollisionShape3D = null
	var min_distance: float = INF
	
	for b in blocks:
		var dist = b.global_position.distance_to(impact_point)
		if dist < min_distance:
			min_distance = dist
			closest_block = b
	
	if closest_block:
		closest_block.take_damage(damage,source,impact_point)
	

func calculate_impact_chunk(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	if not source:
		return
	
	var affected_blocks: Array[Building_Block_V2] = []
	var tank_transform = source.global_transform
	var tank_size = (source.collision_shape.size / 2.0) * 1.2 
	
	var basis_inv = tank_transform.basis.inverse()
	
	var affine_inv = tank_transform.affine_inverse()
	
	for b in blocks:
		if not is_instance_valid(b):
			continue
		
		var block_extents = b.shape.size / 2.0
		var block_pos = b.global_position
		
		if block_pos.distance_to(tank_transform.origin) > (tank_size.length() + block_extents.length() + 1.0):
			continue
		
		var local_block_center = affine_inv * block_pos 
		
		var local_block_extents = Vector3(
			abs(basis_inv.x.x) * block_extents.x + abs(basis_inv.y.x) * block_extents.y + abs(basis_inv.z.x) * block_extents.z,
			abs(basis_inv.x.y) * block_extents.x + abs(basis_inv.y.y) * block_extents.y + abs(basis_inv.z.y) * block_extents.z,
			abs(basis_inv.x.z) * block_extents.x + abs(basis_inv.y.z) * block_extents.y + abs(basis_inv.z.z) * block_extents.z
		)
		
		var limit = tank_size + local_block_extents
		
		if abs(local_block_center.x) <= limit.x and \
		   abs(local_block_center.y) <= limit.y and \
		   abs(local_block_center.z) <= limit.z:
			affected_blocks.append(b)
			
	for a in affected_blocks:
		a.take_damage(damage, source, impact_point)

func block_destroyed(block: Building_Block_V2, type: Building_Block_V2.Block_Types) -> void:
	#print("Antes -> ",blocks.size())
	blocks.erase(block)
	if key_blocks.has(block):
		key_blocks.erase(block)
	
	if blocks.is_empty():
		deactivate()
	
	#print(total_blocks," | ",blocks.size()," | ",key_blocks.size())
	#print("HOLA W",key_blocks.size()," | ",blocks.size())
	
	return
	if key_blocks.is_empty():
		#print("BASIO W")
		destroyed = true
		#use_collision = false
		#set_physics_process(true)
		deactivate()
	#print("Despues -> ",blocks.size())
	
	if blocks.size() < min_blocks:
		return
		deactivate()

func take_explosion(damage: int, source: Vehicle_Rigid, impact_point: Vector3, radius: float) -> void:
	if destroyed:
		return
	
	if impact_point.distance_to(global_position) + building_max_radius <= radius:
		for b in blocks.duplicate():
			b.destroy_now()
		#destroyed = true
		#deactivate()
		return
	
	var radius_squared: float = radius * radius
	
	var affected_blocks: Array[Building_Block_V2] = []
	for b in blocks:
		var dist_squared = b.global_position.distance_squared_to(impact_point)
		if dist_squared <= radius_squared:
			affected_blocks.append(b)
			#b.take_damage(damage, source, impact_point)
	
	for a in affected_blocks:
		a.call_deferred("take_damage",damage, source, impact_point)

func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	calculate_closest_block(damage,source, impact_point)
	return
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 



func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("disabled",false)
	#set_deferred("monitoring", true)
	#set_deferred("monitorable", true)
	

func deactivate() -> void:
	got_destroyed.emit()
	#print("siuuuuuuu V2")
	#damage_zone	.queue_free()
	queue_free()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("disabled",true)
	#set_deferred("monitoring", false)
	#set_deferred("monitorable", false)
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()

func deactivate_collisions() -> void:
	collision_layer = 0
	collision_mask = 0
	for b in blocks:
		#print("PENEEEEEE")
		b.disabled = true


func get_score(score: int) -> void:
	self.score += score


func blocks_of_type(type: Building_Block_V2.Block_Types) -> int:
	var res: int = 0
	
	for b in blocks:
		if b.block_type == type:
			res += 1
	
	return res
