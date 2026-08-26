extends StaticBody3D
class_name Emplacement

var max_armor_points: int = 40
var armor_points: int = 40

signal got_hit(source: Tank_Rigid, impact_point: Vector3)

func take_damage(damage: int, source: Tank_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 
		return
	
	got_hit.emit(source, impact_point)


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	var collision = $CollisionShape3D
	collision.set_deferred("disabled",false)
	#set_deferred("monitoring", true)
	#set_deferred("monitorable", true)
	

func deactivate() -> void:
	
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	var collision = $CollisionShape3D
	collision.set_deferred("disabled",true)
	#set_deferred("monitoring", false)
	#set_deferred("monitorable", false)
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
	


func get_score(score: int) -> void:
	self.score += score
