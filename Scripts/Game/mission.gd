extends Node
class_name Mission

@export var player_spawn: Node3D = null
@export var exfil_zone: Area3D = null

var player: Tank_player_controller = null
var objectives_text: String = ""

var briefing_text: String = "Sample_text"

var player_is_in_exfil_zone = false

var effects_manager: Effects_Manager = Effects_Manager.new()

signal mission_finished(result: bool)
signal update_objectives(objectives: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	add_child(effects_manager)
	
	await get_tree().physics_frame
	
	
	_spawn_player()
	
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
	#player = get_tree().get_first_node_in_group("Player").get_parent() as Tank_player_controller
	
	if not player:
		return
	
	player.tank_rigid.call_deferred("add_to_group","Player")
	
	if player_spawn:
		player.call_deferred("set_global_position", player_spawn.global_position)
		player.call_deferred("set_global_rotation", player_spawn.global_rotation)
	else:
		player.call_deferred("set_global_position", Vector3(0,10,0))
		
		player.call_deferred("set_global_rotation", Vector3(0,0,0))
	
	if exfil_zone:
		exfil_zone.body_entered.connect(_object_enters_exfil_zone)
		exfil_zone.body_exited.connect(_object_exits_exfil_zone)
	
	update_objectives.connect(player.update_Objectives)
	mission_finished.connect(player.finish_mission)

func _check_success_conditions() -> void:
	pass

func _spawn_player() -> void:
	var tank_load = load("res://Prefabs/Player/player_controller.tscn")
	
	player = tank_load.instantiate() as Tank_player_controller
	
	get_tree().current_scene.add_child(player)

func _object_enters_exfil_zone(object: Node3D) -> void:
	if player.tank_rigid == (object as Tank_Rigid):
		player_is_in_exfil_zone = true

func _object_exits_exfil_zone(object: Node3D) -> void:
	if player.tank_rigid == (object as Tank_Rigid):
		player_is_in_exfil_zone = false
