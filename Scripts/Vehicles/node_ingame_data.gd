extends Node
class_name NodeInGameData

var parent_node: Node3D
var position_2d: Vector2 = Vector2.ZERO
var unprojected_position_2d: Vector2 = Vector2.ZERO
var rotation_2d: float = 0.0

enum TypeOfNode {Vehicle,Emplacement}
var type_of_node: TypeOfNode = TypeOfNode.Vehicle

func _init(parent_node: Node3D) -> void:
	self.parent_node = parent_node
	if self.parent_node is Vehicle_Rigid:
		self.parent_node = self.parent_node as Vehicle_Rigid
		type_of_node = TypeOfNode.Vehicle
	if parent_node is Emplacement:
		self.parent_node = self.parent_node as Emplacement
		type_of_node = TypeOfNode.Emplacement
	


func _ready() -> void:
	
	for i in 15:
		await get_tree().process_frame
	activate()

func calculate_unprojected_position(delta: float) -> void:
	if not Tank_camera.INSTANCE:
		return
	unprojected_position_2d = Tank_camera.INSTANCE.unproject_position(parent_node.global_position)
	#print(unprojected_position_2d)

func _process(delta: float) -> void:
	calculate_unprojected_position(delta)

func activate() -> void:
	if not Tank_camera.INSTANCE:
		print("NO ESISTE")
		return
	if parent_node.current_team != Basic_AI.Team.ALLY:
		Tank_camera.INSTANCE.add_unprojected(self)
	
func deactivate() -> void:
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
