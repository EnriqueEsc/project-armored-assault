extends CSGCombiner3D
class_name Building

var blocks: Array[CSGShape3D] = []
var total_blocks: int = 0
var min_blocks: int = 0

var max_armor_points: int = 40
var armor_points: int = 40


func _ready() -> void:
	for b in get_children():
		if b is CSGShape3D and b.visible:
			blocks.append(b)
	
	total_blocks = blocks.size()
	min_blocks = total_blocks/2

func calculate_closest_block(impact_point: Vector3) -> void:
	var closest_block: CSGShape3D = null
	var min_distance: float = INF
	
	for b in blocks:
		var dist = b.global_position.distance_to(impact_point)
		if dist < min_distance:
			min_distance = dist
			closest_block = b
	
	if closest_block:
		closest_block.visible = false
		closest_block.use_collision = false
		blocks.erase(closest_block)
	
	if blocks.size() < min_blocks:
		deactivate()
	

func take_damage(damage: int, source: Tank_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	calculate_closest_block(impact_point)
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
