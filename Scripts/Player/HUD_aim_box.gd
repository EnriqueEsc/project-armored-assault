extends Line2D
class_name HUD_Aim_Box

var marker: Sprite2D = null
var original_color: Color = Color.WHITE
var secondary_container: HBoxContainer = null
var secondary_weapon_indicators: Array[ProgressBar] = []

var primary_container: HBoxContainer = null
var primary_weapon_indicators: Array[ProgressBar] = []

var upper_container: VBoxContainer = null

var enemy_health_bar: ProgressBar = null
var enemy_name: RichTextLabel = null

var hitmarker: RichTextLabel = null
var last_time_hit_shown: float = 0
@export var hit_marker_time: float = 2.0

var cursor: Sprite2D = null

var aim_assist_type: Settings_Manager.Aim_Assist_Type = Settings_Manager.Aim_Assist_Type.None

func _ready() -> void:
	
	call_deferred("set_position",Vector2(1000,1000))
	
	hitmarker = RichTextLabel.new()
	hitmarker.scroll_active = false
	hitmarker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hitmarker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hitmarker.size = Vector2(160,40)
	hitmarker.custom_minimum_size = Vector2(160,40)
	hitmarker.pivot_offset = hitmarker.size / 2.0
	hitmarker.fit_content = true
	hitmarker.text = "HIT"
	hitmarker.add_theme_font_size_override("normal_font_size", 20)
	hitmarker.add_theme_constant_override("outline_size", 5)
	hitmarker.add_theme_color_override("outline_color", Color.BLACK)
	hitmarker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	call_deferred("add_child",hitmarker)
	
	hitmarker.visible = false
	last_time_hit_shown = hit_marker_time
	
	
	var cursor_texture = load("res://Sprites/Test/ShootingPoint.png")
	cursor = Sprite2D.new()
	cursor.texture = cursor_texture
	cursor.scale = Vector2(0.15,0.15)
	cursor.visible = true
	call_deferred("add_child",cursor)
	
	if aim_assist_type != Settings_Manager.Aim_Assist_Type.Box:
		var centered_hitmarker_pos = Vector2(0,30) - hitmarker.pivot_offset
		hitmarker.call_deferred("set_position",centered_hitmarker_pos)
		return
	
	var texture = load("res://Sprites/Test/lock_on.png")
	marker = Sprite2D.new()
	marker.texture = texture
	marker.scale = Vector2(0.15,0.15)
	marker.visible = false
	get_tree().current_scene.call_deferred("add_child",marker)
	
	secondary_container = HBoxContainer.new()
	secondary_container.size = Vector2(200.0,200.0)
	call_deferred("add_child",secondary_container)
	secondary_container.call_deferred("set_position",points[2] + Vector2(10,0))
	
	primary_container = HBoxContainer.new()
	primary_container.size = Vector2(200.0,200.0)
	primary_container.layout_direction = Control.LAYOUT_DIRECTION_RTL
	call_deferred("add_child",primary_container)
	
	var primary_width = primary_container.size.x
	var primary_aux = points[3] - Vector2(10,0) - Vector2(primary_width,0.0)
	primary_container.call_deferred("set_position", primary_aux)
	
	
	
	upper_container = VBoxContainer.new()
	upper_container.size = Vector2(200.0,200.0)
	upper_container.alignment = BoxContainer.ALIGNMENT_END
	call_deferred("add_child",upper_container)
	
	
	
	enemy_name = RichTextLabel.new()
	enemy_name.custom_minimum_size = Vector2(200.0, 20.0)
	enemy_name.size = Vector2(200.0, 20.0)
	enemy_name.scroll_active = false
	upper_container.call_deferred("add_child",enemy_name)
	enemy_name.text = ""
	enemy_name.visible = false
	
	
	enemy_health_bar = ProgressBar.new()
	enemy_health_bar.add_theme_font_size_override("font_size", 1)
	enemy_health_bar.custom_minimum_size = Vector2(200.0, 10.0)
	enemy_health_bar.size = Vector2(200.0, 5.0)
	enemy_health_bar.scale = Vector2(1,0.3)
	enemy_health_bar.show_percentage = false
	upper_container.call_deferred("add_child",enemy_health_bar)
	if not points.is_empty():
		enemy_health_bar.call_deferred("set_position",points[3] - Vector2(0.0,15.0))
	else:
		enemy_health_bar.call_deferred("set_position",Vector2(100,100))
	enemy_health_bar.visible = false
	
	
	
	var upper_height = upper_container.size.y
	var upper_aux = points[3] - Vector2(0,15) - Vector2(0.0, upper_height)
	upper_container.call_deferred("set_position", upper_aux)
	
	var centered_hitmarker_pos = Vector2(0,-points[2].y * 1.2) - hitmarker.pivot_offset
	hitmarker.call_deferred("set_position",centered_hitmarker_pos)
	

func draw_line_to_points(array: Array[NodeInGameData]) -> void:
	var counter: int = 0
	var c_points: Array[Vector2] = []
	for a in array:
		c_points.append(a.unprojected_position_2d)
	
	points = c_points

func draw_aim_box_basic(aim_assist_type: Settings_Manager.Aim_Assist_Type, size: float, original_color: Color = self.original_color,width: float = 2.0) -> void:
	self.aim_assist_type = aim_assist_type
	if self.aim_assist_type != Settings_Manager.Aim_Assist_Type.Box:
		return
	
	var box_corners: Array[Vector2] = [Vector2(-size,size),Vector2(size,size),Vector2(size,-size),Vector2(-size,-size),Vector2(-size,size)]
	points = box_corners
	self.original_color = original_color
	modulate = self.original_color
	self.width = width
	
	if marker:
		marker.modulate = self.original_color
	
	#check_is_inside_box()


func change_color(original_color) -> void:

	self.original_color = original_color
	modulate = self.original_color
	
	if marker:
		marker.modulate = self.original_color

func check_is_inside_box(node: NodeInGameData, color: Color = Color.GREEN) -> NodeInGameData:
	#var ret = null
	if not is_instance_valid(node) or not node.parent_node.visible:
		modulate = color
		return null
	if Geometry2D.is_point_in_polygon(to_local(node.unprojected_position_2d),points):
		#print(node.unprojected_position_2d," ",to_local(node.unprojected_position_2d)," | ",Geometry2D.is_point_in_polygon(to_local(node.unprojected_position_2d),points)," | ",node.parent_node.global_position)
		modulate = Color.RED
		return node
	
	modulate = color
	return null

func show_marker(node: NodeInGameData, color: Color = original_color) -> void:
	if node:
		color = Color.RED
	if color != modulate:
		modulate = color
	if not node and marker:
		marker.visible = false
		enemy_health_bar.visible = false
		enemy_name.visible = false
		return
	
	if not marker.visible:
		marker.visible = true
		enemy_health_bar.visible = true
		enemy_name.visible = true
	
	if marker.modulate != color:
		marker.modulate = color
	
	if enemy_health_bar.value != node.get_ap_percent():
		enemy_health_bar.value = node.get_ap_percent()
	
	if enemy_name.text != node.get_node_name():
		enemy_name.text = node.get_node_name()
	
	#if not marker.position.is_equal_approx(node.unprojected_position_2d):
	marker.position = node.unprojected_position_2d

func show_visible(b: bool) -> void:
	visible = b
	if aim_assist_type != Settings_Manager.Aim_Assist_Type.Box:
		return
	if marker.visible != b:
		if not b:
			marker.visible = false
			enemy_health_bar.visible = false
			enemy_name.visible = false

func set_secondary_indicator_fill(value: float, index: int) -> void:
	#print("aaaaaaaaaaaaaaaa ",value," | ",index," | ",secondary_weapon_indicators.size())
	if index >= secondary_weapon_indicators.size():
		return
	secondary_weapon_indicators[index].value = value


func set_primary_indicator_fill(value: float, index: int) -> void:
	#print("aaaaaaaaaaaaaaaa ",value," | ",index," | ",primary_weapon_indicators.size())
	if index >= primary_weapon_indicators.size():
		return
	primary_weapon_indicators[index].value = value



func set_indicator_fill(value: float, priority: Vehicle_turret.Turret_Priority, index: int) -> void:
	#print("aaaaaaaaaaaaaaaa ",value," | ",index," | ",secondary_weapon_indicators.size())
	var indicators: Array[ProgressBar] = []
	match priority:
		Vehicle_turret.Turret_Priority.Main:
			indicators = primary_weapon_indicators
			
		Vehicle_turret.Turret_Priority.Secondary:
			indicators = secondary_weapon_indicators
			
		_:
			indicators = primary_weapon_indicators
			
	if index >= indicators.size():
		return
	indicators[index].value = value



func create_indicator(priority: Vehicle_turret.Turret_Priority) -> int:
	if aim_assist_type != Settings_Manager.Aim_Assist_Type.Box:
		return 0
	var container: HBoxContainer = null
	var indicators: Array[ProgressBar] = []
	var pivot = Vector2(10,0)
	match priority:
		Vehicle_turret.Turret_Priority.Main:
			container = primary_container
			indicators = primary_weapon_indicators
			pivot *= -1
			
		Vehicle_turret.Turret_Priority.Secondary:
			container = secondary_container
			indicators = secondary_weapon_indicators
			
		_:
			container = primary_container
			indicators = primary_weapon_indicators
	
	var weapon_indicator = ProgressBar.new()
	weapon_indicator.value = 100.0
	weapon_indicator.size = Vector2(10.0, 200.0)
	container.call_deferred("add_child", weapon_indicator)
	weapon_indicator.call_deferred("set_position",points[2] + pivot)
	weapon_indicator.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	weapon_indicator.show_percentage = false
	weapon_indicator.custom_minimum_size = weapon_indicator.size
	indicators.append(weapon_indicator)
	return indicators.size() - 1

func hits_enemy() -> void:
	last_time_hit_shown = 0.0
	hitmarker.visible = true

func _process(delta: float) -> void:
	if last_time_hit_shown <= hit_marker_time:
		last_time_hit_shown += delta
		if last_time_hit_shown >= hit_marker_time:
			hitmarker.visible = false
