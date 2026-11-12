extends Node
class_name NodeInGameData

var parent_node: Node3D
var position_2d: Vector2 = Vector2.ZERO
var unprojected_position_2d: Vector2 = Vector2.ZERO
var rotation_2d: float = 0.0

enum TypeOfNode {Vehicle,Emplacement}
var type_of_node: TypeOfNode = TypeOfNode.Vehicle

var node_test: Sprite2D = null
var pre_position: Vector3 = Vector3.ZERO

var collision_lenght: float = 0.0

var icon_pref = preload("res://Sprites/Test/1771646306126.png")
var rect = null
var message_color: Color = Color.GREEN


func _init(parent_node: Node3D) -> void:
	self.parent_node = parent_node
	if self.parent_node is Vehicle_Rigid:
		self.parent_node = self.parent_node as Vehicle_Rigid
		type_of_node = TypeOfNode.Vehicle
		self.collision_lenght = self.parent_node.collision_lenght
	if parent_node is Emplacement:
		self.parent_node = self.parent_node as Emplacement
		type_of_node = TypeOfNode.Emplacement
		self.collision_lenght = self.parent_node.collision_lenght
	

func create_node_test() -> void:
	var texture = load("res://Sprites/Test/ShootingPoint.png")
	node_test = Sprite2D.new()
	node_test.texture = texture
	node_test.scale = Vector2.ONE * 0.5
	get_tree().current_scene.call_deferred("add_child",node_test)

func move_node_test() -> void:
	if not node_test:
		return
	
	node_test.position = Tank_camera.INSTANCE.unproject_position(pre_position)

func _ready() -> void:
	
	for i in 15:
		await get_tree().process_frame
	activate()
	create_HUD_Icon()
	#create_node_test()

func create_HUD_Icon() -> void:
	if not HUD_Minimap.INSTANCE:
		return
	'''
	rect = TextureRect.new()
	rect.texture = icon_pref
	rect.custom_maximum_size = Vector2.ONE * 20
	rect.custom_minimum_size = Vector2.ZERO
	rect.size = rect.custom_maximum_size
	print("SIZE ",rect.size)
	rect.pivot_offset = rect.size / 2.0
	rect.modulate = message_color
	HUD_Minimap.INSTANCE.view.call_deferred("add_child",rect)
	return
	'''
	rect = ColorRect.new()
	rect.size = Vector2.ONE * 10
	rect.pivot_offset = rect.size / 2.0
	rect.modulate = message_color
	HUD_Minimap.INSTANCE.view.call_deferred("add_child",rect)

func calculate_unprojected_position(delta: float) -> void:
	if not Tank_camera.INSTANCE:
		return
	unprojected_position_2d = Tank_camera.INSTANCE.unproject_position(parent_node.global_position)
	
		#rect.position = HUD_Minimap.INSTANCE.update_position(unprojected_position_2d,rect.size)
	#print(unprojected_position_2d)


func update_HUD_icon(delta: float) -> void:
	if not HUD_Minimap.INSTANCE:
		return
	if rect:
		var pos = HUD_Minimap.INSTANCE.update_position_old(parent_node.global_position,rect.size)
		var aux = rect.position
		if not aux.is_equal_approx(pos):
			rect.position = pos
			
		return
		var rot = rect.rotation_degrees
		aux = -rect.rotation_degrees
		if not is_equal_approx(aux,rot):
			rect.rotation_degrees = aux

func _process(delta: float) -> void:
	calculate_unprojected_position(delta)
	update_HUD_icon(delta)
	#calculate_pre_position()
	#move_node_test()

func activate() -> void:
	if rect:
		rect.visible = true
		rect.process_mode = Node.PROCESS_MODE_ALWAYS
	if not Tank_camera.INSTANCE:
		print("NO ESISTE")
		return
	if parent_node.current_team != Basic_AI.Team.ALLY:
		Tank_camera.INSTANCE.add_unprojected(self)
	
func deactivate() -> void:
	if rect:
		rect.visible = false
		rect.process_mode = Node.PROCESS_MODE_DISABLED
	if not Tank_camera.INSTANCE:
		return
	if parent_node.current_team != Basic_AI.Team.ALLY:
		Tank_camera.INSTANCE.remove_unprojected(self)

func get_ap_percent() -> float:
	if parent_node.has_method("get_ap_percent"):
		return parent_node.get_ap_percent()
	return 0.0

func get_node_name() -> String:
	if parent_node is Vehicle_Rigid:
		return parent_node.vehicle_pilot_name
	if parent_node is Emplacement:
		return parent_node.emplacement_name
	return ""

func calculate_pre_position() -> void:
	var res: Vector3 = parent_node.global_position
	if type_of_node == TypeOfNode.Vehicle:
		res += parent_node.velocity
	pre_position = res
	
func get_pre_position(factor: float) -> Vector3:
	var res: Vector3 = parent_node.global_position
	if type_of_node == TypeOfNode.Vehicle:
		res += (parent_node.velocity * factor)
	pre_position = res
	return res

func update_color(color: Color) -> void:
	if color == message_color:
		return
	message_color = color
	if not rect:
		return
	rect.modulate = message_color
