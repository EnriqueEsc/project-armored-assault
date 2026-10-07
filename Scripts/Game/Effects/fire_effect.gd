extends GPUParticles3D
class_name Fire_Effect

@onready var fake_light_effect: Mesh_Instance_3D_Effect = $Fake_Light
var counter: float = 0.0
var intensity: float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
