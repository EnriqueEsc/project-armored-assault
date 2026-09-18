extends Node3D
class_name Array_Comms

signal gets_disabled



enum Team {ENEMY, ALLY}
@export var current_team: Team = Team.ENEMY

var player_ref: Node3D = null
var last_known_position: Vector3 = Vector3.ZERO

@export var max_vision_distance: float = 10.0


var scan_timer: float = 0.0

var player_ref_buffer: Node3D = null

var allies: Array[Basic_AI] = []

func _ready() -> void:
	
	var parent_col = get_parent_node_3d()
	var grand_parent_col = parent_col.get_parent_node_3d()
	
	
	#current_team = randi_range(0,Team.size()-1)
	
	match current_team:
		Team.ENEMY:
			print("ENEMY")
			self.add_to_group("Enemy")
		Team.ALLY:
			print("ALLY")
			self.add_to_group("Player")


	await get_tree().physics_frame

	for i in 10:
		await get_tree().physics_frame
	
	
	match current_team:
		Team.ENEMY:
			
			for e in get_tree().get_nodes_in_group("Enemy"):
				if e != self:
				#if e is Tank_Rigid and e != tank_rigid:
					for c in e.get_children():
						if c is Basic_AI:
							allies.append(c)
							#continue
		Team.ALLY:
			
			for e in get_tree().get_nodes_in_group("Player"):
				if e != self:
				#if e is Tank_Rigid and e != tank_rigid:
					for c in e.get_children():
						if c is Basic_AI:
							allies.append(c)
							#continue
	
	var turret_rigid = null
	turret_rigid = get_parent_node_3d() as Emplacement
	var emplacement = null
	
	if turret_rigid:
		emplacement = turret_rigid.get_parent_node_3d() as Emplacement
	
	


func got_hit(source: Node3D, impact_point: Vector3) -> void:
	player_ref = source


func activate() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT

func deactivate() -> void:
	gets_disabled.emit()
	network_collapse()
	process_mode = Node.PROCESS_MODE_DISABLED

func alert_close_allies() -> void:
	#player_ref = player_ref_buffer
	if player_ref == null:
		return
	
	for a in allies:
		if global_position.distance_to(a.tank_rigid.global_position) < max_vision_distance:
			if a.has_method("get_report") and a != self:
				a.get_report(player_ref,player_ref.global_position)
				#print(a)
	
	scan_timer = 0.0
	print("RETRANSMITIENDO ",player_ref)
	player_ref = null


func network_collapse() -> void:
	#player_ref = player_ref_buffer
	
	for a in allies:
		if global_position.distance_to(a.tank_rigid.global_position) < max_vision_distance:
			if a.has_method("get_report") and a != self:
				a.network_collapse(player_ref,player_ref.global_position)
				#print(a)
	

func _process(delta: float) -> void:
	scan_timer += delta
	if scan_timer > 1:
		alert_close_allies()
