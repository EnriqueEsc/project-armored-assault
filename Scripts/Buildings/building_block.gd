extends CSGShape3D
class_name Building_Block

var max_armor_points: int = 40
var armor_points: int = 40

signal got_destroyed(building_block: Building_Block)


func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	#print(armor_points)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		got_destroyed.emit(self)
		deactivate() 

func deactivate() -> void:
	
	queue_free()
	return
	visible = false
	use_collision = false
	
	return
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	
