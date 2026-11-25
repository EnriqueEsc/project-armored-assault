extends StaticBody3D
class_name Building_Base

var collision: CollisionShape3D = null
var mesh: MeshInstance3D = null

@export var max_armor_points: int = 40
var armor_points: int = 40

var destroyed: bool = false


var effects_manager: Effects_Manager = null


signal got_destroyed



func _ready() -> void:
	
	max_armor_points = randi_range(3,7)
	max_armor_points *= 10
	
	
	set_physics_process(false)
	
	await get_tree().physics_frame
	
	effects_manager = Effects_Manager.INSTANCE



func take_explosion(damage: int, source: Vehicle_Rigid, impact_point: Vector3, radius: float) -> void:
	if destroyed:
		return
	take_damage(damage,source,impact_point)

func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	if destroyed:
		return
	
	#print("AY")
	
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	#print("AAAAAAAAAAAA ",armor_points)
	
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
	deactivate_collisions()
	#print("siuuuuuuu V2")
	#damage_zone	.queue_free()
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

func deactivate_collisions() -> void:
	collision_layer = 0
	collision_mask = 0
	if collision:
		collision.disabled = true

func deactivate_visuals() -> void:
	if not mesh:
		return
	mesh.visible = false
	if effects_manager:
		effects_manager.debris_from_pool(global_position)

func get_score(score: int) -> void:
	self.score += score
