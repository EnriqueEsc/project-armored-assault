extends Panel
class_name HUD_Minimap

var player: NodeInGameData = null
var player_rigid: Tank_Rigid = null
static var INSTANCE: HUD_Minimap = null
var center: Vector2 = Vector2.ZERO
@onready var view: Control = $Control
@export var custom_size: Vector2 = Vector2(200,200)
@export var radius: float = 15
var base_scale: float = 30.0
var current_scale: float = 30.0

var range_line: Line2D = null
var range_text: RichTextLabel = null
var visual_range: float = 0.0

var rotate_icons: bool = false

var color: Color = Color.WHITE

func singleton() -> void:
	if(HUD_Minimap.INSTANCE != null):
		queue_free()
		return
	HUD_Minimap.INSTANCE = self

func update_radius(radius: float, runtime_set: bool = true) -> void:
	if is_equal_approx(self.radius,radius) and runtime_set:
		return
	self.radius = radius
	var aux = self.radius/5.0
	current_scale = base_scale / aux

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton()
	initialize_minimap()
	pass # Replace with function body.

func initialize_minimap() -> void:
	update_radius(30,false)
	resize_minimap(custom_size,false)
	var line = Line2D.new()
	line.add_point(Vector2(10,size.y - 20))
	line.width = 3.0
	line.add_point(Vector2((size.x/2.0),size.y - 20))
	call_deferred("add_child",line)
	range_line = line
	var factor = (size.x/200.0) * (line.points[0].distance_to(line.points[1])/(size.x/2.0))
	visual_range = radius * factor
	var label = RichTextLabel.new()
	label.scroll_active = false
	label.text = str(visual_range)+"m"
	label.custom_minimum_size = Vector2(50,25)
	label.size = label.custom_minimum_size
	call_deferred("add_child",label)
	label.call_deferred("set_position",line.points[0])
	label.add_theme_font_size_override("normal_font_size", 12)
	range_text = label
	

func resize_minimap(size: Vector2 = self.size, runtime_set: bool = true) -> void:
	if self.size.is_equal_approx(size) and runtime_set:
		return
	self.size = size
	center = self.size / 2.0
	view.pivot_offset = center

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		return
	#print("PLAYER ",player.global_position," CAMERA",Tank_camera.INSTANCE.global_rotation_degrees)
	
	rotate_map()
	
	pass

func rotate_map() -> void:
	if not Tank_camera.INSTANCE:
		return
	var final_rotation = Tank_camera.INSTANCE.global_rotation_degrees.y - 180.0
	var degrees = view.rotation_degrees
	if is_equal_approx(degrees, final_rotation):
		return
	
	#print("ROT ",degrees," ",final_rotation," ",is_equal_approx(degrees, final_rotation))
	view.rotation_degrees = final_rotation

func update_position(pos: Vector2, size: Vector2 = Vector2.ONE) -> Vector2:
	var res = center
	if player:
		res = (center - (size/2.0)) + ((player.unprojected_position_2d - pos) / 10.0)
		
	return res
	
func update_position_old(pos: Vector3, size: Vector2 = Vector2.ONE,rotation: float = 0.0, rotation_enabled: bool = rotate_icons) -> Vector2:
	var res = center
	if player_rigid:
		res = (center - (size/2.0)) + Vector2(player_rigid.global_position.x - pos.x,player_rigid.global_position.z - pos.z) * current_scale
		#print("DISTANCE ",Tank_camera.INSTANCE.unproject_position(player_rigid.global_position).distance_to(Tank_camera.INSTANCE.unproject_position(pos))," ",player.rect.position.distance_to(res))
		#15 meters
		#3 actual units
		
	return res


func set_player(node: NodeInGameData) -> void:
	player = node
	if not player_rigid:
		if player.parent_node != player_rigid:
			player_rigid = player.parent_node

func update_color(color: Color) -> void:
	self.color = color
	if range_line.modulate != self.color:
		range_line.modulate = self.color
	if range_text.modulate != self.color:
		range_text.modulate = self.color
