extends Node
class_name Settings_Manager

static var INSTANCE: Settings_Manager = null
var running_time: float = 0

static var Vehicle_Material_Override: StandardMaterial3D = null
static var Vehicle_Material_Overlay: StandardMaterial3D = null
static var Building_Shader_Material = preload("res://Shaders/see_tank.gdshader")
static var Folliage_Shader_Material = preload("res://Shaders/tree_wind.gdshader")

const SETTINGS_PATH = "user://settings.cfg"
var settings_file: ConfigFile = ConfigFile.new()

var current_tank_used_in_game: Tank_Data = null

var fullscreen: bool = false

var aim_3d: bool = true
var aim_guideline: bool = true
var aim_limited: bool = false
var third_person: bool = false
var use_csg: bool = false

var see_trough_buildings: bool = true
var max_effects: int = 30
var max_shake_strength: float = 0.2
var mouse_visible: bool = false

var enable_emmisions: bool = true

#var enable_mouse_assist: bool = true

enum Destruction_Effects_Mode {Disabled, On_Block_Only, On_Building_Only, Always}
var destruction_effects_mode: Destruction_Effects_Mode = Destruction_Effects_Mode.Always

var move_type: Tank_player_controller.Move_Types = Tank_player_controller.Move_Types.Axial
var controller_aim: bool = false
var use_vibration: bool = false

enum Aim_Assist_Type {None, ToCenter, Box}
var aim_assist_type: Aim_Assist_Type = Aim_Assist_Type.None

var current_save: String = "user://test.json"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton()
	Settings_Manager.INSTANCE.load_settings()
	
	initialize_materials()
	
	await get_tree().process_frame
	
	Save_File_Manager.INSTANCE.CURRENT_PATH = current_save
	if Save_File_Manager.INSTANCE.load_game():
		return
	Save_File_Manager.INSTANCE.save_game()
	Save_File_Manager.INSTANCE.load_game()


func singleton() -> void:
	if(Settings_Manager.INSTANCE != null):
		queue_free()
		return
	Settings_Manager.INSTANCE = self




func initialize_materials() -> void:
	var shader = ShaderMaterial.new()
	shader.shader = Building_Shader_Material
	Building_Shader_Material = shader as ShaderMaterial
	
	shader = ShaderMaterial.new()
	shader.shader = Folliage_Shader_Material
	shader.set_shader_parameter("base_color",Color.WHITE)
	shader.set_shader_parameter("tip_color",Color.WHITE)
	shader.set_shader_parameter("max_height",0.0)
	Folliage_Shader_Material = shader as ShaderMaterial
	
	Vehicle_Material_Overlay = StandardMaterial3D.new()
	Vehicle_Material_Override = StandardMaterial3D.new()
	
	Vehicle_Material_Override.metallic_specular = 0.0
	Vehicle_Material_Override.metallic = 0.0
	Vehicle_Material_Override.roughness = 0.0
	Vehicle_Material_Override.render_priority = 0
	Vehicle_Material_Override.stencil_mode = BaseMaterial3D.STENCIL_MODE_OUTLINE
	Vehicle_Material_Override.stencil_color = Color.BLACK
	
	Vehicle_Material_Overlay.transparency =BaseMaterial3D.TRANSPARENCY_ALPHA
	Vehicle_Material_Overlay.render_priority = 1
	#Vehicle_Material_Overlay.stencil_outline_thickness = 0.3
	Vehicle_Material_Overlay.albedo_color.a = 0.0
	if Settings_Manager.INSTANCE.enable_emmisions:
		#Vehicle_Material_Overlay.emission_enabled = true
		Vehicle_Material_Overlay.emission = Color.ORANGE
		Vehicle_Material_Overlay.albedo_color = Color.BLACK
		#Vehicle_Material_Overlay.emission_energy_multiplier = 10.0
		var noise_texture = NoiseTexture2D.new()
		noise_texture.seamless = true
		noise_texture.noise = FastNoiseLite.new()
		var ramp = Gradient.new()
		ramp.add_point(0.0,Color.from_rgba8(0,0,0,0))
		ramp.add_point(0.5,Color.from_rgba8(0,0,0,255))
		ramp.add_point(1.0,Color.WHITE)
		noise_texture.color_ramp = ramp
		Vehicle_Material_Overlay.albedo_color = Color.from_rgba8(255,155,50,255)
		Vehicle_Material_Overlay.albedo_texture = noise_texture
		
		Vehicle_Material_Overlay.albedo_color.a = 0.0
				


func save_settings() -> void:
	settings_file.set_value("Video","fullscreen",fullscreen)
	settings_file.set_value("Game","aim_3d",aim_3d)
	settings_file.set_value("Game","aim_guideline",aim_guideline)
	settings_file.set_value("Game","aim_limited",aim_limited)
	settings_file.set_value("Game","third_person",third_person)
	settings_file.set_value("Game","use_csg",use_csg)
	settings_file.set_value("Game","see_trough_buildings",see_trough_buildings)
	settings_file.set_value("Game","max_shake_strength",max_shake_strength)
	settings_file.set_value("Game","max_effects",max_effects)
	settings_file.set_value("Game","mouse_visible",mouse_visible)
	settings_file.set_value("Controls","controller_aim",controller_aim)
	settings_file.set_value("Controls","move_type",move_type)
	settings_file.set_value("Video","enable_emmisions",enable_emmisions)
	#settings_file.set_value("Game","enable_mouse_assist",enable_mouse_assist)
	settings_file.set_value("Game","aim_assist_type",aim_assist_type)
	settings_file.set_value("Game","destruction_effects_mode",destruction_effects_mode)
	settings_file.set_value("Controls","use_vibration",use_vibration)
	settings_file.save(SETTINGS_PATH)
	print("SETTINGS GUARDADOS")
	print(settings_file,settings_file.get_value("Video","fullscreen",fullscreen))
	apply_settings()
	
func load_settings() -> void:
	if settings_file.load(SETTINGS_PATH) == OK:
		print("existe")
		fullscreen = settings_file.get_value("Video","fullscreen",fullscreen)
		aim_3d = settings_file.get_value("Game","aim_3d",aim_3d)
		aim_guideline = settings_file.get_value("Game","aim_guideline",aim_guideline)
		aim_limited = settings_file.get_value("Game","aim_limited",aim_limited)
		third_person = settings_file.get_value("Game","third_person",third_person)
		use_csg = settings_file.get_value("Game","use_csg",use_csg)
		see_trough_buildings = settings_file.get_value("Game","see_trough_buildings",see_trough_buildings)
		max_shake_strength = settings_file.get_value("Game","max_shake_strength",max_shake_strength)
		max_effects = settings_file.get_value("Game","max_effects",max_effects)
		
		destruction_effects_mode = settings_file.get_value("Game","destruction_effects_mode",destruction_effects_mode)
		
		
		#enable_mouse_assist = settings_file.get_value("Game","enable_mouse_assist",enable_mouse_assist)
		
		aim_assist_type = settings_file.get_value("Game","aim_assist_type",aim_assist_type)
		
		enable_emmisions = settings_file.get_value("Video","enable_emmisions",enable_emmisions)
		
		mouse_visible = settings_file.get_value("Game","mouse_visible",mouse_visible)
		
		controller_aim = settings_file.get_value("Controls","controller_aim",controller_aim)
		move_type = settings_file.get_value("Controls","move_type",move_type)
		use_vibration = settings_file.get_value("Controls","use_vibration",use_vibration)
		apply_settings()
	else:
		print("no existe")
		save_settings()


func apply_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
