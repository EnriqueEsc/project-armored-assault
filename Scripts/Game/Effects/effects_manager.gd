extends Node
class_name Effects_Manager

static var INSTANCE: Effects_Manager = null

var max_particle_emmiters: int = 30

var explosion_prefab = load("res://Prefabs/Effects/explosion.tscn")
var explosion_pool: Array[GPUParticles3D] = []
var explosion_active: Array[GPUParticles3D] = []


var collapse_prefab = load("res://Prefabs/Effects/collapse.tscn")
var collapse_pool: Array[GPUParticles3D] = []
var collapse_active: Array[GPUParticles3D] = []



var sparks_prefab = load("res://Prefabs/Effects/sparks.tscn")
var sparks_pool: Array[GPUParticles3D] = []
var sparks_active: Array[GPUParticles3D] = []


var failed_sparks_prefab = load("res://Prefabs/Effects/failed_sparks.tscn")
var failed_sparks_pool: Array[GPUParticles3D] = []
var failed_sparks_active: Array[GPUParticles3D] = []


var debris_prefab = load("res://Prefabs/Effects/debris.tscn")
var debris_pool: Array[GPUParticles3D] = []
var debris_active: Array[GPUParticles3D] = []


var fire_prefab = load("res://Prefabs/Effects/fire.tscn")
var fire_pool: Array[Fire_Effect] = []
var fire_active: Array[Fire_Effect] = []


var heat_prefab = load("res://Prefabs/Effects/ground_trail.tscn")
var heat_pool: Array[GPUParticles3D] = []
var heat_active: Array[GPUParticles3D] = []

var marker_prefab = load("res://Sprites/Test/lock_on.png")
var marker_pool: Array[Sprite_Effect] = []
var marker_active: Array[Sprite_Effect] = []

var shoot_prefab = load("res://Prefabs/Effects/shoot_effect.tscn")
var shoot_pool: Array[Sprite_Effect] = []
var shoot_active: Array[Sprite_Effect] = []



var fake_light_prefab = load("res://Prefabs/Effects/fake_light.tscn")
var fake_light_pool: Array[MeshInstance3D] = []
var fake_light_active: Array[MeshInstance3D] = []

@export var tick: float = 0.2
var time_since_last_tick: float = 1.0

var sprites_auto_clear: Array[Sprite_Effect] = []

var meshes_auto_clear: Array[MeshInstance3D] = []

var enable_emission: bool = true

func _ready() -> void:
	singleton()
	
	create_effects()
	
func singleton() -> void:
	if(Effects_Manager.INSTANCE != null):
		queue_free()
		return
	Effects_Manager.INSTANCE = self
	
	time_since_last_tick = tick

func create_effects() -> void:
	max_particle_emmiters = Settings_Manager.INSTANCE.max_effects
	enable_emission = Settings_Manager.INSTANCE.enable_emmisions
	
	for i in max_particle_emmiters:
		
		var explosion = explosion_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",explosion)
		explosion.finished.connect(explosion_to_pool.bind(explosion))
		deactivate_effect(explosion)
		explosion_pool.append(explosion)
		
		var collapse = collapse_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",collapse)
		collapse.finished.connect(collapse_to_pool.bind(collapse))
		deactivate_effect(collapse)
		collapse_pool.append(collapse)
		
		
		var sparks = sparks_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",sparks)
		sparks.finished.connect(sparks_to_pool.bind(sparks))
		deactivate_effect(sparks)
		sparks_pool.append(sparks)
		set_emission_in_gpu_particles(sparks)
		
		
		var failed_sparks = failed_sparks_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",failed_sparks)
		failed_sparks.finished.connect(failed_sparks_to_pool.bind(failed_sparks))
		deactivate_effect(failed_sparks)
		failed_sparks_pool.append(failed_sparks)
		set_emission_in_gpu_particles(failed_sparks)
		
		
		var debris = debris_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",debris)
		debris.finished.connect(debris_to_pool.bind(debris))
		deactivate_effect(debris)
		debris_pool.append(debris)
		
		
		var fire = fire_prefab.instantiate() as Fire_Effect
		get_tree().current_scene.call_deferred("add_child",fire)
		fire.one_shot = true
		#fire.lifetime = 10
		fire.finished.connect(fire_to_pool.bind(fire))
		deactivate_effect(fire)
		fire_pool.append(fire)
		
		var heat = heat_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",heat)
		heat.one_shot = false
		#heat.lifetime = 10
		#heat.finished.connect(heat_to_pool.bind(heat))
		deactivate_effect(heat)
		heat_pool.append(heat)
		
		
		
		var marker = Sprite_Effect.new()
		marker.texture = marker_prefab
		get_tree().current_scene.call_deferred("add_child",marker)
		marker.no_depth_test = true
		marker.modulate = Color.RED
		marker.modulate.a = 0.5
		marker.render_priority = 90
		marker.rotation_degrees.x = 90
		deactivate_sprite(marker)
		marker_pool.append(marker)
	
	
		var fake_light = fake_light_prefab.instantiate() as Mesh_Instance_3D_Effect
		#fake_light.texture = fake_light_prefab
		get_tree().current_scene.call_deferred("add_child",fake_light)
		#fake_light.no_depth_test = true
		#fake_light.modulate = Color.RED
		#fake_light.modulate.a = 0.5
		#fake_light.render_priority = 90
		#fake_light.rotation_degrees.x = 90
		var shader = fake_light.material_override as ShaderMaterial
		if shader:
			shader = shader.duplicate() as ShaderMaterial
			fake_light.material_override = shader
		if fake_light.mesh:
			fake_light.mesh = fake_light.mesh.duplicate()
		deactivate_mesh_instance_3d(fake_light)
		#fake_light.visible = false
		fake_light_pool.append(fake_light)
		#set_emission_in_gpu_particles(fake_light)
		
		var shoot = shoot_prefab.instantiate() as Sprite_Effect
		get_tree().current_scene.call_deferred("add_child",shoot)
		#shoot.no_depth_test = true
		shoot.modulate = Color.YELLOW
		shoot.modulate.a = 0.5
		shoot.render_priority = 90
		shoot.rotation_degrees.x = 90
		deactivate_sprite(shoot)
		shoot_pool.append(shoot)



func explosion_from_pool(position: Vector3, radius: float) -> void:
	var explosion: GPUParticles3D = null
	if explosion_pool.size() <= 0:
		explosion = explosion_active.pop_front()
	else:
		explosion = explosion_pool.pop_front()
	if explosion:
		explosion_active.push_back(explosion)
		explosion.process_mode = Node.PROCESS_MODE_ALWAYS
		explosion.global_position = position
		explosion.show()
		explosion.restart()
		
		fake_light_from_pool(position, Vector2.ONE * radius)

func explosion_to_pool(explosion: GPUParticles3D) -> void:
	explosion_active.erase(explosion)
	explosion_pool.push_back(explosion)
	deactivate_effect(explosion)




func sparks_from_pool(position: Vector3) -> void:
	var sparks: GPUParticles3D = null
	if sparks_pool.size() <= 0:
		sparks = sparks_active.pop_front()
	else:
		sparks = sparks_pool.pop_front()
	if sparks:
		sparks_active.push_back(sparks)
		sparks.process_mode = Node.PROCESS_MODE_ALWAYS
		sparks.global_position = position
		sparks.show()
		sparks.restart()
		
		var emission = get_emission_in_gpu_particles(sparks)
		if emission != Color.BLACK:
			fake_light_from_pool(position,Vector2(1.5,1.5),emission)
		else:
			fake_light_from_pool(position,Vector2(1.5,1.5))

func sparks_to_pool(sparks: GPUParticles3D) -> void:
	sparks_active.erase(sparks)
	sparks_pool.push_back(sparks)
	deactivate_effect(sparks)


func failed_sparks_from_pool(position: Vector3) -> void:
	var failed_sparks: GPUParticles3D = null
	if failed_sparks_pool.size() <= 0:
		failed_sparks = failed_sparks_active.pop_front()
	else:
		failed_sparks = failed_sparks_pool.pop_front()
	if failed_sparks:
		failed_sparks_active.push_back(failed_sparks)
		failed_sparks.process_mode = Node.PROCESS_MODE_ALWAYS
		failed_sparks.global_position = position
		failed_sparks.show()
		failed_sparks.restart()
		
		var emission = get_emission_in_gpu_particles(failed_sparks)
		if emission != Color.BLACK:
			fake_light_from_pool(position,Vector2(0.5,0.5),emission)
		else:
			fake_light_from_pool(position,Vector2(0.5,0.5))

func failed_sparks_to_pool(failed_sparks: GPUParticles3D) -> void:
	failed_sparks_active.erase(failed_sparks)
	failed_sparks_pool.push_back(failed_sparks)
	deactivate_effect(failed_sparks)





func debris_from_pool(position: Vector3) -> void:
	var debris: GPUParticles3D = null
	if debris_pool.size() <= 0:
		debris = debris_active.pop_front()
	else:
		debris = debris_pool.pop_front()
	if debris:
		debris_active.push_back(debris)
		debris.process_mode = Node.PROCESS_MODE_ALWAYS
		debris.global_position = position
		debris.show()
		debris.restart()

func debris_to_pool(debris: GPUParticles3D) -> void:
	debris_active.erase(debris)
	debris_pool.push_back(debris)
	deactivate_effect(debris)


func collapse_from_pool(position: Vector3) -> void:
	
	print(position)
	var collapse: GPUParticles3D
	if collapse_pool.size() <= 0:
		collapse = collapse_active.pop_front()
	else:
		collapse = collapse_pool.pop_front()
	if collapse:
		collapse_active.push_back(collapse)
		collapse.process_mode = Node.PROCESS_MODE_ALWAYS
		collapse.global_position = position
		collapse.show()
		collapse.restart()

func collapse_to_pool(collapse: GPUParticles3D) -> void:
	collapse_active.erase(collapse)
	collapse_pool.push_back(collapse)
	deactivate_effect(collapse)


func fire_from_pool(position: Vector3) -> Fire_Effect:
	#print("EXP ",position)
	#print("Efectos activos: ",fire_active.size())
	var fire: Fire_Effect
	if fire_pool.size() <= 0:
		fire = fire_active.pop_front()
	else:
		fire = fire_pool.pop_front()
	if fire:
		fire_active.push_back(fire)
		fire.process_mode = Node.PROCESS_MODE_ALWAYS
		fire.global_position = position
		fire.counter = 0.0
		if fire.fake_light_effect:
			fire.fake_light_effect.scale = Vector3.ONE
		fire.show()
		fire.restart()
		#fake_light_from_pool(position, Vector2.ONE * 2.0)
	return fire

func fire_to_pool(fire: Fire_Effect) -> void:
	fire_active.erase(fire)
	fire_pool.push_back(fire)
	deactivate_effect(fire)




func heat_from_pool(position: Vector3) -> GPUParticles3D:
	#print("EXP ",position)
	#print("Efectos activos: ",heat_active.size())
	var heat: GPUParticles3D
	if heat_pool.size() <= 0:
		heat = heat_active.pop_front()
	else:
		heat = heat_pool.pop_front()
	if heat:
		heat_active.push_back(heat)
		heat.process_mode = Node.PROCESS_MODE_ALWAYS
		heat.global_position = position
		heat.finished.emit()
		heat.one_shot = false
		heat.show()
		heat.restart()
	
	#print("HEAT")
	return heat

func heat_to_pool(heat: GPUParticles3D) -> void:
	heat_active.erase(heat)
	heat_pool.push_back(heat)
	deactivate_effect(heat)




func marker_from_pool(position: Vector3) -> Sprite_Effect:
	#print("EXP ",position)
	#print("Efectos activos: ",marker_active.size())
	var marker: Sprite_Effect
	if marker_pool.size() <= 0:
		marker = marker_active.pop_front()
	else:
		marker = marker_pool.pop_front()
	if marker:
		marker_active.push_back(marker)
		marker.visible = true
		marker.finished.emit()
		marker.global_position = position
	
	#print("marker")
	return marker

func marker_to_pool(marker: Sprite_Effect) -> void:
	marker_active.erase(marker)
	marker_pool.push_back(marker)
	deactivate_sprite(marker)



func fake_light_from_pool(position: Vector3, scale: Vector2 = Vector2.ONE, color: Color = Color.YELLOW, autoclear: bool = true) -> Mesh_Instance_3D_Effect:
	#print("EXP ",position)
	#print("Efectos activos: ",fake_light_active.size())
	var fake_light: Mesh_Instance_3D_Effect
	if fake_light_pool.size() <= 0:
		fake_light = fake_light_active.pop_front()
	else:
		fake_light = fake_light_pool.pop_front()
	if fake_light:
		fake_light_active.push_back(fake_light)
		
		fake_light.scale = Vector3.ONE * Vector3(scale.x,scale.y,1.0) * randf_range(0.7,1.3)
		
		fake_light.set_instance_shader_parameter("light_color",color)
		
		fake_light.visible = true
		fake_light.finished.emit()
		fake_light.global_position = position
		if autoclear:
			meshes_auto_clear.append(fake_light)
			#print(position, " ",fake_light.mesh.size," ",color)
	
	#print("fake_light")
	return fake_light

func fake_light_to_pool(fake_light: Mesh_Instance_3D_Effect) -> void:
	fake_light_active.erase(fake_light)
	fake_light_pool.push_back(fake_light)
	#fake_light.visible = false
	deactivate_mesh_instance_3d(fake_light)



func shoot_from_pool(position: Vector3, rotation: Vector3 = Vector3.ZERO, scale: float = 1.0, alligment:float = 90.0) -> Sprite_Effect:
	#print("EXP ",position)
	#print("Efectos activos: ",shoot_active.size())
	var shoot: Sprite_Effect
	if shoot_pool.size() <= 0:
		shoot = shoot_active.pop_front()
	else:
		shoot = shoot_pool.pop_front()
	if shoot:
		shoot_active.push_back(shoot)
		shoot.visible = true
		shoot.finished.emit()
		shoot.global_position = position
		shoot.global_rotation = rotation
		shoot.rotate_object_local(Vector3.RIGHT,deg_to_rad(alligment))
		#shoot.rotation_degrees.x += 90
		#shoot.rotation.y = deg_to_rad(randi_range(0,180))
		shoot.rotate_object_local(Vector3.UP,randf_range(0.0, TAU))
		#print(shoot.rotation)
		shoot.scale = Vector3.ONE * scale * randf_range(0.7,1.3)
		sprites_auto_clear.append(shoot)
		fake_light_from_pool(position,Vector2.ONE * scale * 2.5, shoot.modulate)
	
	#print("shoot")
	return shoot

func shoot_to_pool(shoot: Sprite_Effect) -> void:
	shoot_active.erase(shoot)
	shoot_pool.push_back(shoot)
	deactivate_sprite(shoot)


func get_emission_in_gpu_particles(ef: GPUParticles3D) -> Color:
	for n in ef.draw_passes:
		var mesh = ef.get_draw_pass_mesh(n)
		if not mesh:
			continue
		var mat = mesh.surface_get_material(0) as StandardMaterial3D
		if mat.emission_enabled:
			return mat.emission
	return Color.BLACK

func set_emission_in_gpu_particles(ef: GPUParticles3D) -> void:
		for n in ef.draw_passes:
			var mesh = ef.get_draw_pass_mesh(n)
			if not mesh:
				continue
			var mat = mesh.surface_get_material(0) as StandardMaterial3D
			if mat:
				mat.emission_enabled = enable_emission




func deactivate_effect(ef: GPUParticles3D) -> void:
	ef.emitting = false
	ef.hide()
	ef.process_mode = Node.PROCESS_MODE_DISABLED


func deactivate_sprite(ef: Sprite_Effect) -> void:
	ef.deactivate()
	
func deactivate_mesh_instance_3d(ef: Mesh_Instance_3D_Effect) -> void:
	ef.deactivate()

func _process(delta: float) -> void:
	time_since_last_tick += delta
	if time_since_last_tick > tick:
		time_since_last_tick = 0
		
		while not sprites_auto_clear.is_empty():
			deactivate_sprite(sprites_auto_clear.pop_front())
			
		while not meshes_auto_clear.is_empty():
			deactivate_mesh_instance_3d(meshes_auto_clear.pop_front())
