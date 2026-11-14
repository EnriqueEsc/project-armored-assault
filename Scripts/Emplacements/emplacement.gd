extends StaticBody3D
class_name Emplacement

signal gets_disabled

@export var max_armor_points: int = 40
@export var armor_points: int = 40
@export var is_enemy: bool = true

signal got_hit(source: Tank_Rigid, impact_point: Vector3)

signal ap_percent (ap: float)

var damage_effect: GPUParticles3D = null

var ingame_data: NodeInGameData = null
var current_team: Basic_AI.Team = Basic_AI.Team.ALLY
@export var emplacement_name: String = "Emplacement"


var current_status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None
var status_effect_buildup: float = 0.0
var status_effect_res: float = 100.0
var status_effect_ticks: float = 0.0
var status_effect_max_tick: int = 5
@export var status_effect_recovery: float = 5.0
var collision_lenght: float = 0.0

var functioning_children: Array[Node3D] = []

var stagger_max_time: float = 5.0
var stagger_timer: float = 5.0
var staggered: bool = false

var message_color: Color = Color.GREEN


@export var model: Array[MeshInstance3D] = []
var material: BaseMaterial3D = null

var tick: float = 1.0
var last_tick: float = 0.0

var collision_size: Vector3 = Vector3.ZERO

func _ready() -> void:
	if is_enemy:
		message_color = Color.RED
		current_team = Basic_AI.Team.ENEMY
		self.add_to_group("Enemy")
	initialize_effects()
	
	ingame_data = NodeInGameData.new(self,message_color)
	call_deferred("add_child",ingame_data)
	if ingame_data:
		#gets_enabled.connect(ingame_data.activate)
		gets_disabled.connect(ingame_data.deactivate)
		#ingame_data.activate()
	calculate_collision_lenght()
	
	initialize_stencil()
	#update_stencil(BaseMaterial3D.STENCIL_MODE_XRAY)
	
	call_deferred("get_functioning_children")

func take_damage(damage: int, source: Vehicle_Rigid, impact_point: Vector3, status_effect: Vehicle_Rigid.StatusEffects = Vehicle_Rigid.StatusEffects.None) -> void:
	
	if armor_points < 1:
		return
	
	armor_points -= damage
	armor_points = clamp(armor_points,0,max_armor_points)
	
	ap_percent.emit(float(armor_points)/float(max_armor_points) * 100.0)
	
	if status_effect != Vehicle_Rigid.StatusEffects.None:
		status_buildup(damage * 10,status_effect)
	
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
	
	update_visual_damage_overlay()
	
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
	
	if collision_lenght <= 0.0:
		calculate_collision_lenght()
	
	var scale: float = collision_lenght * 5
	var wave_scale: float = collision_lenght
	
	Effects_Manager.INSTANCE.explosion_from_pool(global_position, scale, wave_scale)
	process_mode = Node.PROCESS_MODE_DISABLED
	var collision = $CollisionShape3D
	collision.set_deferred("disabled",true)
	#set_deferred("monitoring", false)
	#set_deferred("monitorable", false)
	
	queue_free()
	
	for c in get_children():
		if c.has_method("deactivate"):
			c.deactivate()
			c.queue_free()
	


func get_score(score: int) -> void:
	self.score += score


func get_ap_percent() -> float:
	return (float(armor_points)/float(max_armor_points) * 100.0)


func status_buildup(value: float, status: Vehicle_Rigid.StatusEffects) -> void:
	if status == Vehicle_Rigid.StatusEffects.PEM and functioning_children.is_empty():
		return
	status_effect_buildup += value
	status_effect_buildup = clampf(status_effect_buildup,0.0,status_effect_res)
	if status_effect_buildup >= status_effect_res:
		current_status_effect = status
		status_effect_max_tick = 5
		status_effect_buildup = 0.0
		exec_status_effect()

func exec_status_effect() -> void:
	if current_status_effect == Vehicle_Rigid.StatusEffects.None:
		return
	
	match current_status_effect:
		Vehicle_Rigid.StatusEffects.Burning:
			take_damage(max_armor_points * 0.10,null,global_position)
			if Effects_Manager.INSTANCE:
				Effects_Manager.INSTANCE.fire_from_pool(global_position,collision_size)
			
			#print("ME QUEMO")
		Vehicle_Rigid.StatusEffects.PEM:
			if functioning_children.is_empty():
				return
			if Effects_Manager.INSTANCE:
				if collision_lenght <= 0.0:
					calculate_collision_lenght()
				Effects_Manager.INSTANCE.explo_wave_from_pool(global_position,collision_lenght * 1.2,collision_lenght * 1.2,Color.SKY_BLUE)
			#print("AY ME PARO")
			if not staggered:
				stagger()
				status_effect_max_tick = 999.0
		_:
			return

func _process(delta: float) -> void:
	
	#process_mode = Node.PROCESS_MODE_DISABLED
	
	last_tick += delta
	if last_tick > tick:
		update_stencil(2)
		last_tick = 0
	
	if status_effect_buildup > 0.0:
		status_effect_buildup -= status_effect_recovery * delta
		if status_effect_buildup < 0.0:
			status_effect_buildup = 0.0
		#print("BUILDUP ",status_effect_buildup)
	
	if current_status_effect != Vehicle_Rigid.StatusEffects.None and status_effect_ticks < 1:
		status_effect_ticks += delta
		
		if status_effect_max_tick < 1:
			current_status_effect = Vehicle_Rigid.StatusEffects.None
		
		if status_effect_ticks > 1:
			status_effect_ticks = 0.0
			status_effect_max_tick -= 1
			exec_status_effect()
	
	if stagger_timer < stagger_max_time:
		stagger_timer += delta
		if stagger_timer >= stagger_max_time:
			staggered = false
			status_effect_max_tick = 0.0
			enable_functioning_children(not staggered)
	

func stagger() -> void:
	staggered = true
	stagger_timer = 0.0
	enable_functioning_children(not staggered)

func enable_functioning_children(enable: bool) -> void:
	for c in functioning_children:
		#print("DEACTIVE ",enable)
		c.set_process(enable)
		c.set_physics_process(enable)

func calculate_collision_lenght() -> void:
	collision_lenght = 0.0
	collision_size = Vector3.ZERO
	var counter: float = 0
	
	for c in get_children():
		if c is CollisionShape3D and c.shape is BoxShape3D:
			collision_lenght += c.shape.size.length()
			collision_size += c.shape.size
			counter += 1.0
			if ingame_data and ingame_data.collision_lenght != collision_lenght:
				ingame_data.collision_lenght = collision_lenght
	collision_size *= counter
func get_functioning_children() -> void:
	functioning_children = []
	
	for c in get_children():
		if c is Array_Comms or c is TurretAI:
			functioning_children.append(c)

func initialize_stencil() -> void:
	
	
	model.clear()
	
	for c in get_children():
		find_model_recursive(c)
	
	material = StandardMaterial3D.new()
	if not model.is_empty():
		for m in model:
			if is_instance_valid(m):
				var albedo_texture = null
				var aux = m.get_active_material(0).duplicate()
				if aux is StandardMaterial3D:
					albedo_texture = aux.albedo_texture
				var override = Settings_Manager.INSTANCE.Vehicle_Material_Override.duplicate() if Settings_Manager.INSTANCE else null
				var overlay = Settings_Manager.INSTANCE.Vehicle_Material_Overlay.duplicate() if Settings_Manager.INSTANCE else null
				if override:
					override = override as StandardMaterial3D
					#override.stencil_outline_thickness = 1.0
					if albedo_texture:
						override.albedo_texture = albedo_texture
					m.material_override = override
				if overlay:
					overlay.stencil_color = message_color
					material = overlay.duplicate()
					m.material_overlay = material
				


func update_stencil(stencil_mode: BaseMaterial3D.StencilMode) -> void:
	
	if not material:
		return
	if stencil_mode == material.stencil_mode:
		return
	if not model.is_empty():
		#material.stencil_mode = stencil_mode
		for m in model:
			if is_instance_valid(m):
				#print("sssss ",m," ",material.stencil_mode)
				#m.material_override = material
				#m.material_override = m.get_active_material(0).duplicate()
				if not m.material_overlay:
					continue
				var mat = m.material_overlay.stencil_mode
				if mat == stencil_mode:
					continue
				material.stencil_mode = stencil_mode
				m.material_overlay.stencil_mode = stencil_mode
				#print("SEXO ",m)

func find_model_recursive(node: Node) -> void:
	if node is Emplacement:
		node.current_team = current_team
		return
	if not node.visible:
		return
	if node is TurretAI:
		node.current_team = current_team
		node._start_turret()
	if node is MeshInstance3D and not model.has(node):
		model.append(node)
	for child in node.get_children():
		#if child is Building_Block_V2:
		#	child.got_destroyed.connect(update_navmesh)
		find_model_recursive(child)

func update_visual_damage_overlay() -> void:
	
	if not Settings_Manager.INSTANCE.enable_emmisions:
		return
		#overlay.emission_energy_multiplier = 10.0
	if not model.is_empty():
		for m in model:
			if is_instance_valid(m):
				if not is_instance_valid(m.material_overlay):
					continue
				#print("sssss ",m," ",material.stencil_mode)
				#m.material_override = material
				#m.material_override = m.get_active_material(0).duplicate()
				var percent = 1.0 - (float(armor_points) / float(max_armor_points))
				percent = clampf(remap(percent, 0.0, 0.7, 0.0, 1.0), 0.0, 1.0)
				#var mat = m.material.albedo_color.a
				if is_equal_approx(percent, m.material_overlay.albedo_color.a):
					continue
				m.material_overlay.albedo_color.a = percent
