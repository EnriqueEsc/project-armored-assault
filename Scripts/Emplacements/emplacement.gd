extends StaticBody3D
class_name Emplacement

signal gets_disabled

@export var max_armor_points: int = 40
@export var armor_points: int = 40
@export var is_enemy: bool = true

signal got_hit(source: Tank_Rigid, impact_point: Vector3)

signal ap_percent (ap: float)

var damage_effect: GPUParticles3D = null

func _ready() -> void:
	if is_enemy:
		self.add_to_group("Enemy")
	initialize_effects()

func take_damage(damage: int, source: Tank_Rigid, impact_point: Vector3) -> void:
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	ap_percent.emit(float(armor_points)/float(max_armor_points) * 100.0)
	
	if armor_points <= 0:
		if source:
			source.get_score(max_armor_points * 4)
			
		#if is_player:
			#self.get_parent().get_parent().death_screen.visible = true
		deactivate() 
		return
	
	got_hit.emit(source, impact_point)


func initialize_effects() -> void:
	var damage_prefab = load("res://Prefabs/Effects/fire.tscn")
	if damage_prefab:
		damage_effect = damage_prefab.instantiate() as GPUParticles3D
		add_child(damage_effect)
		damage_effect.one_shot = false
		damage_effect.emitting = false
		damage_effect.amount = 1
		damage_effect.hide()
		damage_effect.process_mode = Node.PROCESS_MODE_DISABLED
	
	ap_percent.connect(show_visual_damage)

func show_visual_damage(ap: float) -> void:
	if not damage_effect:
		return
	
	if ap <= 50.0:
		if not damage_effect.emitting:
			damage_effect.emitting = true
			damage_effect.show()
			damage_effect.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var particles_ammount:float = remap(ap, 50.0, 10.0, 1.0, 10)
		var final_particles: int = clampi(roundi(particles_ammount),1,10)
		#print("OLAAAAAA ",final_particles)
		if damage_effect.amount != final_particles:
			damage_effect.amount = final_particles


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	var collision = $CollisionShape3D
	collision.set_deferred("disabled",false)
	#set_deferred("monitoring", true)
	#set_deferred("monitorable", true)
	

func deactivate() -> void:
	gets_disabled.emit()
	
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
