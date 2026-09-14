extends Node
class_name Mission

@export var player_spawn: Node3D = null
@export var exfil_zone: Area3D = null

var player: Tank_player_controller = null
var objectives_text: String = ""

var briefing_text: String = "Sample_text"

var player_is_in_exfil_zone = false

var effects_manager: Effects_Manager = Effects_Manager.new()

var dialog_manager: Dialog_Manager = null

signal mission_finished(result: bool)
signal update_objectives(objectives: String)

var fade_time: float = 3.0
var time_since_fade: float = 0.0

var fading_factor: float = 0.0

var black_screen: ColorRect = null
var mission_info_text: Typing_Text = null
var player_dialog: HUD_Dialog = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	
	add_child(effects_manager)
	
	await get_tree().physics_frame
	
	
	_spawn_player()
	
	_link_player()
	
	_set_objectives()

func _mission_failed() -> void:
	mission_finished.emit(false)

func _mission_succeeded() -> void:
	black_screen.visible = true
	time_since_fade = 0.0
	fading_factor = - fading_factor
	mission_info_text.set_text_to_type("....The End....")
	set_process(true)
	mission_finished.emit(true)
	_add_score_to_player()

func _update_current_objectives() -> void:
	pass

func _send_objectives_update() -> void:
	update_objectives.emit(objectives_text)

func _set_objectives() -> void:
	pass

func _process(delta: float) -> void:
	time_since_fade += delta
	black_screen.color.a -= fading_factor * delta
	mission_info_text.modulate.a -= fading_factor * delta
	print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
	if time_since_fade > fade_time:
		if fading_factor > 0.0:
			black_screen.visible = false
			player.set_process(true)
		player_dialog.start_mission()
		set_process(false)

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
	
	dialog_manager = Dialog_Manager.INSTANCE
	dialog_manager.player = player
	
	black_screen = player.HUD_Black_screen
	mission_info_text = player.HUD_Mission_info
	player_dialog = player.HUD_dialog
	fading_factor = black_screen.color.a / fade_time
	
	player.set_process(false)
	
	#set_process(true)
	if mission_info_text:
		_show_mission_info()
		mission_info_text.finished_typing.connect(set_process.bind(true))
	

func _show_mission_info() -> void:
	mission_info_text.set_text_to_type("Mission intel:

Operation: Default shit
Date: Today, duh
			  ")

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

func _add_score_to_player() -> void:
	Save_File_Manager.INSTANCE.score_record(player.tank_rigid.score)
