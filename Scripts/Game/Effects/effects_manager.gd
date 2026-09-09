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

var fire_prefab = load("res://Prefabs/Effects/fire.tscn")
var fire_pool: Array[GPUParticles3D] = []
var fire_active: Array[GPUParticles3D] = []

func _ready() -> void:
	singleton()
	
	create_effects()
	
func singleton() -> void:
	if(Effects_Manager.INSTANCE != null):
		queue_free()
		return
	Effects_Manager.INSTANCE = self

func create_effects() -> void:
	max_particle_emmiters = Settings_Manager.INSTANCE.max_effects
	
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
		
		var fire = fire_prefab.instantiate() as GPUParticles3D
		get_tree().current_scene.call_deferred("add_child",fire)
		fire.one_shot = true
		#fire.lifetime = 10
		fire.finished.connect(fire_to_pool.bind(fire))
		deactivate_effect(fire)
		fire_pool.append(fire)

func explosion_from_pool(position: Vector3) -> void:
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

func explosion_to_pool(explosion: GPUParticles3D) -> void:
	explosion_active.erase(explosion)
	explosion_pool.push_back(explosion)
	deactivate_effect(explosion)

func deactivate_effect(ef: GPUParticles3D) -> void:
	ef.emitting = false
	ef.hide()
	ef.process_mode = Node.PROCESS_MODE_DISABLED




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


func fire_from_pool(position: Vector3) -> GPUParticles3D:
	#print("EXP ",position)
	#print("Efectos activos: ",fire_active.size())
	var fire: GPUParticles3D
	if fire_pool.size() <= 0:
		fire = fire_active.pop_front()
	else:
		fire = fire_pool.pop_front()
	if fire:
		fire_active.push_back(fire)
		fire.process_mode = Node.PROCESS_MODE_ALWAYS
		fire.global_position = position
		fire.show()
		fire.restart()
	return fire

func fire_to_pool(fire: GPUParticles3D) -> void:
	fire_active.erase(fire)
	fire_pool.push_back(fire)
	deactivate_effect(fire)
