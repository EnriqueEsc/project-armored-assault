extends CSGCombiner3D
class_name Building

var blocks: Array[Building_Block] = []
var key_blocks: Array[Building_Block] = []

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

const BLOCK_SCRIPT = preload("res://Scripts/Buildings/building_block.gd")

signal got_destroyed

func _ready() -> void:
	
	max_armor_points = randi_range(1,5)
	
	for b in get_children():
		if b is CSGShape3D and b.visible:
			b.set_script(BLOCK_SCRIPT)
			
			var new_block = b as Building_Block
			
			new_block.max_armor_points = max_armor_points
			new_block.armor_points = max_armor_points
			
			new_block.got_destroyed.connect(block_destroyed)
			
			blocks.append(new_block)
			if new_block.global_position.y < lowest_height:
				lowest_height = new_block.global_position.y
			if abs(new_block.position.x + (new_block.size.x / 0.5)) > building_bounds.x:
				building_bounds.x = abs(new_block.position.x + (new_block.size.x / 0.5))
			if abs(new_block.position.z + (new_block.size.z / 0.5)) > building_bounds.y:
				building_bounds.y = abs(new_block.position.z + (new_block.size.z / 0.5))
	
	for b in blocks:
		if b.global_position.y == lowest_height:
			key_blocks.append(b)
	
	total_blocks = blocks.size()
	min_blocks = total_blocks/2
	
	print(building_bounds)
	
	set_shape_cast()
	
	building_half_extents = damage_zone.shape.size / 2.0
	building_max_radius = building_half_extents.length()
	#global_position.y = 10
	
	await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE

func set_shape_cast() -> void:
	damage_zone = ShapeCast3D.new()
	
	var cube = BoxShape3D.new()
	damage_zone.shape = cube
	
	#damage_zone.collide_with_areas = true
	
	damage_zone.shape.size = Vector3(building_bounds.x,5,building_bounds.y)
	
	get_tree().current_scene.call_deferred("add_child",damage_zone)
	damage_zone.call_deferred("set_global_position", global_position)
	#damage_zone.global_position = global_position
	

func crush_below() -> void:
	damage_zone.force_shapecast_update()
	
	for i in damage_zone.get_collision_count():
		var collider = damage_zone.get_collider(i)
		if collider:
			if collider.has_method("take_damage"):
				collider.take_damage(10,null,collider.global_position)
			if collider.has_method("detonate"):
				collider.detonate

func _physics_process(delta: float) -> void:
	
	if not destroyed:
		return
	
	global_position -= global_basis.y * delta * 2
	
	physics_tick_counter += 1
	if physics_tick_counter >= crush_update_frequency:
		physics_tick_counter = 0
		destruction()


func calculate_closest_block(damage:int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	var closest_block: CSGShape3D = null
	var min_distance: float = INF
	
	for b in blocks:
		var dist = b.global_position.distance_to(impact_point)
		if dist < min_distance:
			min_distance = dist
			closest_block = b
	
	if closest_block:
		closest_block.take_damage(damage,source,impact_point)
	

func destruction() -> void:
	var emmit_collapse_effect: bool = false
	
	'''
	#Caotico
	for b in blocks:
		if b.global_position.y < lowest_height:
			emmit_collapse_effect = true
			b.got_destroyed.emit(b)
			b.deactivate()
	
	if emmit_collapse_effect:
		crush_below()
	
	'''
	
	#Organizado
	
	var chunk: Array[Building_Block] = []
	for b in blocks:
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

func calculate_impact_chunk(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	if not source:
		return
	
	var affected_blocks: Array[Building_Block] = []
	var tank_transform = source.global_transform
	var tank_size = (source.collision_shape.size / 2.0) * 1.2 
	
	var basis_inv = tank_transform.basis.inverse()
	
	var affine_inv = tank_transform.affine_inverse()
	
	for b in blocks:
		var block_extents = b.size / 2.0
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

func block_destroyed(block: Building_Block) -> void:
	blocks.erase(block)
	if key_blocks.has(block):
		key_blocks.erase(block)
	
	if blocks.is_empty():
		deactivate()
	
	if key_blocks.is_empty():
		destroyed = true
		use_collision = false
		#deactivate()
	
	if blocks.size() < min_blocks:
		return
		deactivate()

func take_explosion(damage: int, source: Vehicle_Rigid, impact_point: Vector3, radius: float) -> void:
	if destroyed:
		return
	
	if impact_point.distance_to(global_position) + building_max_radius <= radius:
		for b in blocks:
			b.got_destroyed.emit(b)
		destroyed = true
		deactivate()
		return
	
	var radius_squared: float = radius * radius
	
	var affected_blocks: Array[Building_Block] = []
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
	print("siuuuuuuu")
	queue_free()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("disabled",true)
	#set_deferred("monitoring", false)
	#set_deferred("monitorable", false)
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	


func get_score(score: int) -> void:
	self.score += score
