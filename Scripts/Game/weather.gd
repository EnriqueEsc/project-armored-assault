extends Node
class_name Weather

@export var lightning: OmniLight3D = null
var lightning_tick: float = 1.0
var lightning_timer: float = 0.0

var max_light: float = 0.0

@export var cloud_shadows: Decal = null
@export var viewport: SubViewport = null

var cloud_texture: ImageTexture = null
@export var cloud_tick: float = 0.1
var cloud_timer: float = 0.0

@export var visual_effects: MeshInstance3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if lightning:
		max_light = 16.0 / max(0.1, lightning.omni_range)
		#print("MAX LIGHT ",max_light," ",lightning.omni_range)
		'''
	if cloud_shadows:
		cloud_shadows.texture_albedo = viewport.get_texture()
		'''
	if viewport:
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if not cloud_texture:
		cloud_texture = ImageTexture.new()
		
	
	for i in 10:
		await get_tree().process_frame
	
	if visual_effects and is_instance_valid(Tank_camera.INSTANCE):
		_reparent_visual_effects.call_deferred()
		
	pass # Replace with function body.

func _reparent_visual_effects() -> void:
	visual_effects.reparent(Tank_camera.INSTANCE)
	visual_effects.position = Vector3(0, 0, -0.5)
	visual_effects.rotation_degrees = Vector3(0, 0, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lightning_timer += delta
	if lightning_timer > lightning_tick:
		lightning_func(delta)
	
	cloud_timer += delta
	
	if cloud_timer < cloud_tick:
		return
	cloud_timer = 0.9
	if cloud_shadows and viewport:
		
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		var texture = viewport.get_texture()
		if not texture:
			
			return
		var image = texture.get_image()
		if not image or image.is_empty():
			return
		image.convert(Image.FORMAT_RGBA8)
		cloud_texture.set_image(image)
		cloud_shadows.texture_albedo = cloud_texture


func lightning_func(delta: float) -> void:
	
	var min = randf_range(0.2,0.7)
	var max = randf_range(min + 1.0, 1.8)
	var factor = randf_range(1.0,3.0)
	var time = randf_range(0.8,2.0)
	var pivot = Vector2(Tank_camera.INSTANCE.global_position.x,Tank_camera.INSTANCE.global_position.z) if Tank_camera.INSTANCE else Vector2.ZERO
	var light =  factor * sin(delta * 40.0) * randf_range(min,max)
	light = clampf(light,0.0, light * max_light * 50.0)
	lightning.light_energy = light
	#print("LIGHTNING ",lightning.light_energy," ",sin(delta * 40.0))
	if lightning_timer > lightning_tick + time:
		lightning_tick = randf_range(2.0, 7.0)
		#lightning.position.x = pivot.x + randf_range(-10.0,10.0)
		#lightning.position.z = pivot.y + randf_range(-10.0,10.0)
		lightning.position.x = pivot.x + randf_range(-5.0,5.0)
		lightning.position.z = pivot.y + randf_range(-5.0,5.0)
		lightning_timer = 0.0
		lightning.light_energy = 0.0
