extends StaticBody3D


var max_armor_points: int = 40
var armor_points: int = 40

func take_damage(damage: int, source: Tank_Rigid) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	

func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	


func get_score(score: int) -> void:
	self.score += score
