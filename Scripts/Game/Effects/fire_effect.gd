extends GPUParticles3D
class_name Fire_Effect

@onready var fake_light_effect: Mesh_Instance_3D_Effect = $Fake_Light
var counter: float = 0.0
var intensity: float = 3.0
var fire_3d: GPUParticles3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for c in get_children():
		if c is GPUParticles3D:
			fire_3d = c
	if fire_3d:
		fire_3d.lifetime = lifetime
		fire_3d.one_shot = one_shot
		var mat = fire_3d.draw_pass_1.surface_get_material(0).duplicate()
		fire_3d.draw_pass_1.surface_set_material(0,mat)
		
		mat = fire_3d.process_material.duplicate()
		fire_3d.process_material = mat
		finished.connect(stop_fire)
	counter = lifetime
	fake_light_effect.set_instance_shader_parameter("light_color",Color.YELLOW)
	fake_light_effect.mesh.size = Vector2.ONE


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	counter += delta
	if counter > lifetime:
		counter = 0.0
	light_scale(delta)

func light_scale(delta: float) -> void:
	if not fake_light_effect:
		return
	var scale = sin((counter/lifetime)*PI) * randf_range(0.7,1.3)
	fake_light_effect.scale = Vector3.ONE * scale * intensity
	fake_light_effect.scale.z = 1.0
	
	
	
	
	
	#print(fake_light_effect.scale," ",fake_light_effect.visible," ")

func show_fire(size: Vector3 = Vector3.ONE) -> void:
	show()
	if fire_3d:
		fire_3d.process_mode = Node.PROCESS_MODE_ALWAYS
		fire_3d.show()
		size.y = 0.0
		size /= 2.0
		var len = size.length_squared()
		var aux = fire_3d.process_material as ParticleProcessMaterial
		if len != (aux.scale_max * aux.scale_max ):
			fire_3d.process_material.scale_max = sqrt(len)

func restart_fire() -> void:
	restart()
	if fire_3d:
		fire_3d.restart()
		
func _set(property: StringName, value: Variant) -> bool:
	# Cubre cuando haces particulas.emitting = false
	if property == &"emitting" and value == false and emitting == true:
		stop_fire()
	return false

func stop_fire() -> void:
	if not fire_3d:
		return
	
	fire_3d.emitting = false
	fire_3d.hide()
	fire_3d.process_mode = Node.PROCESS_MODE_DISABLED
