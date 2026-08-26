extends CSGCombiner3D
class_name Building

var blocks: Array[Building_Block] = []
var key_blocks: Array[Building_Block] = []

var building_bounds: Vector2 = Vector2.ZERO

var total_blocks: int = 0
var min_blocks: int = 0

var max_armor_points: int = 40
var armor_points: int = 40

var lowest_height = INF

var destroyed: bool = false

var destruction_sensor: ShapeCast3D

var damage_zone: ShapeCast3D = null

func _ready() -> void:
	
	for b in get_children():
		if b is CSGShape3D and b.visible:
			var block_script = load("res://Scripts/Buildings/building_block.gd")
			b.set_script(block_script)
			
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
	#global_position.y = 10

func set_shape_cast() -> void:
	damage_zone = ShapeCast3D.new()
	
	var cube = BoxShape3D.new()
	damage_zone.shape = cube
	
	damage_zone.collide_with_areas = true
	
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
				collider.take_damage(1,null,collider.global_position)
			if collider.has_method("detonate"):
				collider.detonate

func _physics_process(delta: float) -> void:
	
	if not destroyed:
		return
	
	global_position -= global_basis.y * delta * 3
	
	destruction()


func calculate_closest_block(damage:int, source: Tank_Rigid, impact_point: Vector3) -> void:
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
	#Caotico
	
	for b in blocks:
		if b.global_position.y < lowest_height:
			b.got_destroyed.emit(b)
			b.deactivate()
			crush_below()
	
	
	#Organizado
	'''
	
	var chunk: Array[Building_Block] = []
	for b in blocks:
		if b.global_position.y < lowest_height:
			#b.got_destroyed.emit(b)
			#b.deactivate()
			#crush_below()
			chunk.append(b)
	
	for c in chunk:
		c.got_destroyed.emit(c)
		c.deactivate()
		crush_below()
	
	'''

func block_destroyed(block: Building_Block) -> void:
	blocks.erase(block)
	if key_blocks.has(block):
		key_blocks.erase(block)
	
	
	if key_blocks.is_empty():
		destroyed = true
		use_collision = false
		#deactivate()
	
	if blocks.size() < min_blocks:
		return
		deactivate()

func take_explosion(damage: int, source: Tank_Rigid, impact_point: Vector3, radius: float) -> void:
	if destroyed:
		return
	
	for b in blocks:
		var dist = b.global_position.distance_to(impact_point)
		if dist <= radius:
			b.take_damage(damage,source,impact_point)
	

func take_damage(damage: int, source: Tank_Rigid, impact_point: Vector3) -> void:
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
