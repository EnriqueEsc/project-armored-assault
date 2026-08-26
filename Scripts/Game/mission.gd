extends Node
class_name Mission

var player: Tank_player_controller = null
var objectives_text: String = ""

signal mission_finished(result: bool)
signal update_objectives(objectives: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_tree().physics_frame
	
	_link_player()
	
	_set_objectives()

func _mission_failed() -> void:
	mission_finished.emit(false)

func _mission_succeeded() -> void:
	mission_finished.emit(true)

func _update_current_objectives() -> void:
	pass

func _send_objectives_update() -> void:
	update_objectives.emit(objectives_text)

func _set_objectives() -> void:
	pass

func _link_player() -> void:
	player = get_tree().get_first_node_in_group("Player").get_parent() as Tank_player_controller
	
	if not player:
		return
	
	update_objectives.connect(player.update_Objectives)
	mission_finished.connect(player.finish_mission)

func _check_success_conditions() -> void:
	pass
