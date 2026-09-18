extends Node
class_name Tank_player_controller

signal aim_to(point: Vector3)

@onready var tank_rigid: Tank_Rigid = null
@onready var tank_camera: Tank_camera = $Camera3D

@onready var HUD_mouse: Sprite2D = $HUD/HUD_Player/Icon
@onready var HUD_Lock_on: Sprite2D = $HUD/HUD_Player/Icon/Lock_on
var HUD_aim: Array[Sprite2D] = []
var HUD_aim_3D: Array[Sprite3D] = []
var HUD_Shoot_Ready: Array[TextureProgressBar] = []
var HUD_height_line: Array[Line2D] = []


@onready var HUD_AP: RichTextLabel = $HUD/HUD_Player/HUD_AP
@onready var HUD_Score: RichTextLabel = $HUD/HUD_Player/HUD_Score
@onready var HUD_Velocimeter: RichTextLabel = $HUD/HUD_Player/HUD_Velocimeter
@onready var HUD_Objectives: RichTextLabel = $HUD/HUD_Player/HUD_Objectives

@onready var HUD_AP_Bar: ProgressBar = $HUD/HUD_Player/HUD_AP_Bar

@onready var HUD_Boss_info: HUD_Boss_Info = $HUD/HUD_Player/HUD_Boss_Info

@onready var HUD_Death_Screen: Control = $HUD/Death_Screen
@onready var HUD_Victory_Screen: Control = $HUD/Victory


@onready var HUD_Map: Map_Visualization = $HUD/HUD_Player/Map

@onready var pause_menu: Pause_menu = $Pause_menu

@export var color: Color = Color.GREEN

@export var max_armor_points: int = 120

@onready var HUD_Outline_SubViewport: SubViewport = $Outline_Rect/SubViewport
@onready var HUD_3D_SubViewport: SubViewport = $UI_3D_Rect/SubViewport

@onready var HUD_Hitmarker: RichTextLabel = $HUD/HUD_Player/Icon/HUD_Hitmarker

@onready var HUD_dialog: HUD_Dialog = $HUD/HUD_Player/HUD_Dialog

@onready var HUD_Black_screen: ColorRect = $HUD/HUD_Player/Black_screen/HUD_Black_Screen
@onready var HUD_Mission_info: Typing_Text = $HUD/HUD_Player/Black_screen/HUD_Black_Screen/Mission_info

var mission_finished = false
var is_destroyed = false

var aim_point_scale_ref: float = 7.5
var aim_point_original_scale: Vector2 = Vector2.ONE

var aim_guideline: bool = false
var aim_3d: bool = false
var third_person: bool = false

var last_time_hit_shown: float = 0
@export var hit_marker_time: float = 2.0

var targeted_enemies: Array[Vehicle_Rigid] = []

var lock_on: bool = false
var enemy_locked: Vehicle_Rigid = null

var bellow_75: bool = true
var bellow_50: bool = true
var bellow_25: bool = true
var bellow_15: bool = true
var bellow_5: bool = true

var ready_to_shoot: bool = true

var transition_to_game: bool = false


var controller_move: bool = false
var controller_aim: bool = false
var aim_dir_input: Vector2 = Vector2(3.0,0.0)
var aim_dir_3d: Vector3 = Vector3.ZERO

var mouse_visible: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tank_load
	var tank_data
	if Settings_Manager.INSTANCE.current_tank_used_in_game:
		tank_data = Settings_Manager.INSTANCE.current_tank_used_in_game
		if tank_data.tank_Name == "mk_-2inferno":
			tank_load = load("res://Prefabs/Player/inferno.tscn")
		elif tank_data.tank_Name != "MK_01 vindicator":
			tank_load = load("res://Prefabs/Player/tank.tscn")
		else:
			tank_load = load("res://Prefabs/Player/endavour.tscn")
	else:
		tank_load = load("res://Prefabs/Player/endavour.tscn")
		tank_data = load("res://Data/Tanks/mk-0_test.tres") as Tank_Data
	
	tank_rigid = tank_load.instantiate() as Tank_Rigid
	
	
	add_child(tank_rigid)
	
	#tank_rigid.global_rotation = Vector3.ZERO
	print(" POSITION TANK ",rad_to_deg(tank_rigid.global_rotation.y))
	
	tank_rigid.tank_Data = tank_data
	tank_rigid.tank_Data._apply_values(tank_rigid)
	
	tank_rigid.add_to_group("Player")
	
	tank_rigid.hp_changed.connect(update_AP)
	tank_rigid.score_changed.connect(update_Score)
	tank_rigid.velocimeter.connect(update_Velocimeter)
	tank_rigid.ap_percent.connect(update_AP_Bar)
	
	HUD_Death_Screen.visible = false
	HUD_Victory_Screen.visible = false
	HUD_Map.visible = false
	HUD_Boss_info.show_boss_info()
	
	
	HUD_Hitmarker.visible = false
	last_time_hit_shown = hit_marker_time
	HUD_Lock_on.visible = lock_on
	
	tank_rigid.shoot_recharge.connect(shoot_ready)
	
	tank_rigid.shakes.connect(tank_camera.start_shake)
	
	#tank_rigid.max_armor_points = max_armor_points
	#tank_rigid.armor_points = max_armor_points
	
	update_HUD()
	
	var sub_viewports_scale: int = 1
	
	if HUD_3D_SubViewport:
		HUD_3D_SubViewport.world_3d = get_viewport().world_3d
		HUD_3D_SubViewport.size = get_viewport().size / sub_viewports_scale
	if HUD_Outline_SubViewport:
		HUD_Outline_SubViewport.world_3d = get_viewport().world_3d
		HUD_Outline_SubViewport.size = get_viewport().size / sub_viewports_scale
	
	tank_camera.player = tank_rigid
	
	
	#await get_tree().physics_frame
	#Node.print_orphan_nodes()
	#change_HUD_color(color)
	
	tank_rigid.embraces_damage.connect(dialog_hit)
	tank_rigid.shoot_signal.connect(dialog_fire)
	tank_rigid.gets_crushed.connect(dialog_building_collapsing)
	
	
	
	
	await get_tree().physics_frame
	
	aim_guideline = Settings_Manager.INSTANCE.aim_guideline
	aim_3d = Settings_Manager.INSTANCE.aim_3d
	third_person = Settings_Manager.INSTANCE.third_person
	
	controller_aim = Settings_Manager.INSTANCE.controller_aim
	controller_move = Settings_Manager.INSTANCE.controller_move
	
	mouse_visible = Settings_Manager.INSTANCE.mouse_visible
	
	if not mouse_visible:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
	for t in tank_rigid.vehicle_turrets:
		
		t.target.connect(target_enemy)
		
		aim_to.connect(t.rotate_turret_to_point_3d)
		var new_aim = Sprite2D.new()
		new_aim.texture = load("res://Sprites/Test/MousePointer.png")
		var new_ready = TextureProgressBar.new()
		new_ready.texture_progress = load("res://Sprites/Test/ShootingPoint.png")
		var new_line = Line2D.new()
		new_line.width = 3
		new_line.points = [Vector2(0,0),Vector2(0,0)]
		
		$HUD/HUD_Player.add_child(new_aim)
		$HUD/HUD_Player.move_child(new_aim,0)
		$HUD/HUD_Player.add_child(new_line)
		$HUD/HUD_Player.move_child(new_line,0)
		new_aim.add_child(new_ready)
		new_aim.scale = Vector2(0.15,0.15)
		new_ready.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		new_ready.scale = Vector2(1.3,1.3)
		new_ready.position = Vector2(-166.667,-166.667)
		
		
		HUD_aim.append(new_aim)
		#new_aim.visible = false
		HUD_Shoot_Ready.append(new_ready)
		HUD_height_line.append(new_line)
		
		
		
		var new_aim_3d = Sprite3D.new()
		new_aim_3d.texture = load("res://Sprites/Test/MousePointer.png")
		new_aim_3d.scale = Vector3(0.4,0.4,0.4)
		new_aim_3d.no_depth_test = true
		
		#new_aim_3d.set_layer_mask_value(1, false)
		#new_aim_3d.set_layer_mask_value(11, true)
		new_aim_3d.render_priority = 100
		
		get_tree().current_scene.add_child(new_aim_3d)
		HUD_aim_3D.append(new_aim_3d)
		
		if aim_3d:
			new_aim.visible = false
			new_ready.visible = false
		else:
			new_aim_3d.visible = false
	
	if not HUD_aim.is_empty():
		aim_point_original_scale = HUD_aim[0].scale
	
	pause_menu.game_state.connect(show_HUD)
	pause_menu.color_change.connect(change_HUD_color)
	pause_menu.set_color(color)
	
	if not tank_rigid.vehicle_turrets.is_empty():
		tank_rigid.fire_rate_prim = tank_rigid.vehicle_turrets[0].fire_rate_prim
	
	if third_person:
		tank_camera.reparent(tank_rigid,true)
		tank_camera.position = Vector3(0,0.328,-1)
		tank_camera.rotation_degrees = Vector3(0,180,0)

	tank_rigid.hits_enemy.connect(hits_enemy)
	
	await get_tree().process_frame
	HUD_dialog.add_to_buffer(Dialog_data.new("Main Systems","Activating combat mode.",color,"main_systems"))

func color_HUD() -> void:
		#HUD_aim.modulate = color
		HUD_mouse.modulate = color
		HUD_Score.modulate = color
		HUD_AP.modulate = color
		HUD_Velocimeter.modulate = color
		HUD_Objectives.modulate = color
		HUD_AP_Bar.modulate = color
		HUD_Hitmarker.modulate = color
		HUD_Boss_info.color_boss_info(color)
		
		for l in HUD_height_line:
			l.modulate = color
		
		for a in HUD_aim:
			a.modulate = color
		
		for a in HUD_aim_3D:
			a.modulate = color
	

func shoot_ready(charge: float) -> void:
	for s in HUD_Shoot_Ready:
		s.value = charge
	if charge > 99 and not ready_to_shoot:
		ready_to_shoot = true
		var crew_speak: int = randi_range(0,4)
		if crew_speak == 0:
			var dialogs: Array[String] = ["Weapons loaded.","Ready to shoot"]
			HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 3",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino3"))
		
		

func _physics_process(delta: float) -> void:
	if not third_person:
		tank_camera.move_cam(tank_rigid.position, delta)
		$Outline_Rect/SubViewport/Camera3D.global_position = tank_camera.global_position
		$Outline_Rect/SubViewport/Camera3D.global_rotation = tank_camera.global_rotation
		$UI_3D_Rect/SubViewport/Camera3D.global_position = tank_camera.global_position
		$UI_3D_Rect/SubViewport/Camera3D.global_rotation = tank_camera.global_rotation
	#tank_rigid.allign_with_floor(delta)
	
	if transition_to_game:
		return
	
	if pause_menu.visible:
		return
	
	#print(tank_camera.get_mouse_3d_pos())
	
	var pointer_pos: Vector3 = Vector3.ZERO
	
	
	
	if lock_on:
		#print(enemy_locked)
		pointer_pos = enemy_locked.global_position
		HUD_mouse.position = tank_camera.unproject_position(pointer_pos)
	else:
		if controller_aim:
		#pointer_pos = tank_camera.get_mouse_3d_pos()
		#HUD_mouse.position = get_viewport().get_mouse_position()
			aim_dir_input = Input.get_vector("Aim_Left","Aim_Right","Aim_Up","Aim_Down").normalized() * 3 if Input.get_vector("Aim_Left","Aim_Right","Aim_Up","Aim_Down").length_squared() > 0.2 else aim_dir_input
			aim_dir_3d = tank_rigid.global_position + Vector3(aim_dir_input.x,0.0,aim_dir_input.y)
			pointer_pos = aim_dir_3d
			HUD_mouse.position = tank_camera.unproject_position(pointer_pos)
		else:
			pointer_pos = tank_camera.get_mouse_3d_pos()
			HUD_mouse.position = get_viewport().get_mouse_position()
	#HUD_aim.scale = aim_new_scale
	
	#print(tank_rigid.get_aim_point_3d())
	var counter: int = 0
	for a in HUD_aim:
		
		var aim_point = tank_rigid.get_aim_point_3d(counter, tank_rigid.vehicle_turrets[counter].global_position.distance_to(pointer_pos))
		
		var height_ground_pos = aim_point
		height_ground_pos.y = tank_rigid.global_position.y
		
		#print(tank_camera.global_position.y - (aim_point.y))
		
		var aim_new_scale = (aim_point_scale_ref / (tank_camera.global_position.y - (aim_point.y))) * aim_point_original_scale
		HUD_aim[counter].scale = aim_new_scale
		
		HUD_aim[counter].position = tank_camera.unproject_position(tank_rigid.get_aim_point_3d(counter, tank_rigid.vehicle_turrets[counter].global_position.distance_to(pointer_pos)))
		
		if aim_guideline:
			HUD_height_line[counter].points = [tank_camera.unproject_position(tank_rigid.vehicle_turrets[counter].global_position),HUD_aim[counter].position,tank_camera.unproject_position(height_ground_pos)]
		else:
			HUD_height_line[counter].points = [tank_camera.unproject_position(height_ground_pos),HUD_aim[counter].position]
		
		
		var point = tank_rigid.get_aim_point_3d(counter, tank_rigid.vehicle_turrets[counter].global_position.distance_to(pointer_pos))
		var normal = tank_rigid.get_aim_point_3d_normal(counter)
		HUD_aim_3D[counter].position = point
		
		var up = Vector3.UP
		if abs(normal.dot(Vector3.UP)) > 0.99:
			up = Vector3.FORWARD
		HUD_aim_3D[counter].look_at(HUD_aim_3D[counter].position + normal, up, true)
		#HUD_aim_3D[counter].position = point + normal * 0.01
		
		
		
		counter += 1
	#HUD_aim.position = tank_rigid.get_aim_point(get_viewport().get_mouse_position())
	
	#HUD_height_line.points = [tank_camera.unproject_position(height_ground_pos),HUD_aim.position]
	

func add_text_to_buffer(name: String, dialog: String, char_image: String = "default"):
	var new_dialog = Dialog_data.new(name,dialog,color,char_image)
	HUD_dialog.add_to_buffer(new_dialog)

func add_text_to_buffer_max_prior(name: String, dialog: String, char_image: String = "default"):
	var new_dialog = Dialog_data.new(name,dialog,color,char_image)
	HUD_dialog.add_to_buffer_max_prior(new_dialog)

func add_text_to_buffer_low_prior(name: String, dialog: String, char_image: String = "default"):
	var new_dialog = Dialog_data.new(name,dialog,color,char_image)
	HUD_dialog.add_to_buffer_low_prior(new_dialog)

func display_text(name: String, dialog: String, char_image: String = "default"):
	var new_dialog = Dialog_data.new(name,dialog,color,char_image)
	HUD_dialog.display_dialog(new_dialog)

func add_dialog_to_buffer(dialog: Dialog_data):
	HUD_dialog.add_to_buffer(dialog)


func add_dialog_to_buffer_max_prior(dialog: Dialog_data):
	HUD_dialog.add_to_buffer_max_prior(dialog)
	
func add_dialog_to_buffer_low_prior(dialog: Dialog_data):
	HUD_dialog.add_to_buffer_low_prior(dialog)

func display_dialog(dialog: Dialog_data):
	HUD_dialog.display_dialog(dialog)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if pause_menu.visible:
		return
	
	if is_destroyed:
		if Input.is_action_just_pressed("Shoot"):
			get_tree().reload_current_scene()
		return
	
	if mission_finished:
		if Input.is_action_just_pressed("Shoot"):
			#get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			get_tree().change_scene_to_file("res://Scenes/after_mission.tscn")
		return
	
	if Input.is_action_just_pressed("Reload"):
		get_tree().reload_current_scene()
		return
	
	var input_dir := Input.get_vector("Left","Right","Forward","Backward")
	
	#print(get_viewport().get_mouse_position())
	
	
	if tank_rigid.vehicle_turrets[0].fire_mode == 0 and Input.is_action_just_pressed("Shoot"):
		tank_rigid.shoot()
	
	if tank_rigid.vehicle_turrets[0].fire_mode == 1 and Input.is_action_pressed("Shoot"):
		tank_rigid.shoot()
	
	if Input.is_action_just_pressed("Attachment"):
		tank_rigid.use_attachment()
	
	if controller_move:
		controller_movement(input_dir,delta)
	else:
		tank_rigid.move(input_dir, delta)
	
	
	#tank_rigid.rotate_turret_to_point(get_viewport().get_mouse_position())
	
	#tank_rigid.rotate_turret_to_point_3d(tank_camera.get_mouse_3d_pos())
	if lock_on:
		aim_to.emit(enemy_locked.global_position)
	else:
		if controller_aim:
			aim_to.emit(aim_dir_3d)
		else:
			aim_to.emit(tank_camera.get_mouse_3d_pos())
		#print("AIM ",aim_dir," ",aim_dir.length_squared())
	
	if Input.is_action_just_pressed("Map"):
		HUD_Map.visible = not HUD_Map.visible
	
	if Input.is_action_just_pressed("Boost"):
		tank_rigid.quick_boost()
	
	if Input.is_action_just_pressed("LockOn"):
		lock_on = !lock_on
		if not lock_on:
			enemy_locked = null
			HUD_Lock_on.visible = lock_on
			return
		var lock = tank_camera.get_closest_enemy_to_mouse(tank_camera.get_mouse_3d_pos())
		if lock:
			enemy_locked = lock
			if enemy_locked.gets_disabled.is_connected(untarget_enemy.bind(enemy_locked)):
				lock_on = false
				enemy_locked.gets_disabled.disconnect(untarget_enemy.bind(enemy_locked))
				#enemy_locked = null
			enemy_locked.gets_disabled.connect(untarget_enemy.bind(enemy_locked))
			lock_on = true
		else:
			lock_on = false
			enemy_locked = null
		HUD_Lock_on.visible = lock_on
	
	
	if last_time_hit_shown <= hit_marker_time:
		last_time_hit_shown += delta
		if last_time_hit_shown >= hit_marker_time:
			HUD_Hitmarker.visible = false


func controller_movement(target_pos: Vector2, delta: float) -> void:
	var next_pos: Vector3 = tank_rigid.global_position + Vector3(target_pos.x,0.0,target_pos.y)
	
	print(target_pos)
	
	if target_pos == Vector2.ZERO:
		tank_rigid.move(Vector2.ZERO, delta)
		return
	
	var dir_to_path = tank_rigid.global_position.direction_to(next_pos)
	dir_to_path.y = 0.0
	dir_to_path = dir_to_path.normalized()
	
	var forward = tank_rigid.global_transform.basis.z.normalized()
	var angle = forward.signed_angle_to(dir_to_path, tank_rigid.global_basis.y)
	
	var input_x: float = -clamp(angle, -1.0, 1.0)
	
	input_x = clamp(input_x, -1.0, 1.0)
	
	var input_y: float = 1.0 if abs(angle) < 1.8 else 0.0
	
	#print(input_x,",",input_y)
	tank_rigid.move(Vector2(input_x, -input_y), delta)


func update_HUD() -> void:
	update_AP(tank_rigid.armor_points)
	update_Score(tank_rigid.score)

func update_AP(ap: int) -> void:
	HUD_AP.text = (str(ap) +" AP")
	
	if ap <= 0:
		destruction()

func change_HUD_color(c: Color) -> void:
	color = c
	color_HUD()

func update_Score(score: int) -> void:
	HUD_Score.text = ("Score: "+str(score))

func update_Velocimeter(velocity: float) -> void:
	var final_vel = "%.2f" % (velocity * 5)
	HUD_Velocimeter.text = (final_vel+" Km/h")

func update_Objectives(objectives: String) -> void:
	HUD_Objectives.text = objectives

func update_AP_Bar(percent: float) -> void:
	HUD_AP_Bar.value = percent
	
	if percent <= 75 and bellow_75:
		HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Main Systems","Armor integrity at "+str(int(percent))+"%",color,"main_systems"))
		bellow_75 = false
		return
	
	if percent <= 50 and bellow_50:
		HUD_dialog.add_to_buffer(Dialog_data.new("Main Systems","Armor integrity at "+str(int(percent))+"%",color,"main_systems"))
		bellow_50 = false
		return
	
	if percent <= 25 and bellow_25:
		HUD_dialog.add_to_buffer(Dialog_data.new("Main Systems","Armor integrity at "+str(int(percent))+"%
Take evasive action",color,"main_systems"))
		bellow_25 = false
		return
	
	if percent <= 15 and bellow_15:
		HUD_dialog.add_to_buffer(Dialog_data.new("Main Systems","WARNING Armor integrity at "+str(int(percent))+"%",color,"main_systems"))
		bellow_15 = false
		return
	
	if percent <= 5 and bellow_5:
		HUD_dialog.display_dialog(Dialog_data.new("Main Systems","WARNING WARNING WARNING
Armor integrity at "+str(int(percent))+"% CRITICAL",color,"main_systems"))
		bellow_5 = false
		return
		
	if percent <= 0:
		HUD_dialog.display_dialog(Dialog_data.new("Main Systems","WARNING WARNING WARNING
Critcal system failiure",color,"main_systems"))
		return

func dialog_fire() -> void:
	ready_to_shoot = false
	var crew_speak: int = randi_range(0,2)
	if crew_speak == 0:
		HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 3","Fire.",color,"rhino3"))

	

func dialog_hit(damage: int) -> void:
	if damage < 10:
		return
	var dialogs: Array[String] = ["The hull is getting crushed","Evade!!!.","We will need a new tank after this mission.","I don't want to die, do something!"]
	var crew_speak: int = randi_range(0,4)
	
	if crew_speak == 0:
		HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 2",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino2"))


func show_HUD(state: bool) -> void:
	
	if is_destroyed or mission_finished:
		state = false
		HUD_Boss_info.update_boss_active(state)
	
	if not mouse_visible:
		if state:
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	#HUD_aim.visible = state
	HUD_mouse.visible = state
	HUD_Score.visible = state
	HUD_AP.visible = state
	HUD_Velocimeter.visible = state
	HUD_Objectives.visible = state
	HUD_AP_Bar.visible = state
	HUD_Boss_info.show_boss_info()
	#HUD_height_line.visible = state
	HUD_Map.visible = false
	
	HUD_dialog.visible = (state and HUD_dialog.is_active) or mission_finished
	
	for l in HUD_height_line:
		l.visible = state
	
	if aim_3d:
		for a in HUD_aim_3D:
			a.visible = state
		return
	
	for a in HUD_aim:
		a.visible = state

func destruction() -> void:
		is_destroyed = true
		
		show_HUD(false)
		
		HUD_Death_Screen.visible = true
		
		return

func finish_mission(result: bool) -> void:
		mission_finished = true
		
		show_HUD(false)
		
		if result:
			
			HUD_Victory_Screen.visible = true
			tank_rigid.move(Vector2.ZERO,1)
			return
		
		destruction()
		return
	

func hits_enemy() -> void:
	last_time_hit_shown = 0.0
	HUD_Hitmarker.visible = true
	dialog_hit_enemy()

func dialog_hit_enemy() -> void:
	
	var crew_speak: int = randi_range(0,2)
	if crew_speak == 0:
		var who: int = randi_range(0,2)
		if who == 0:
			var dialogs: Array[String] = ["Beautiful.","Good shoot"]
			HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 3",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino3"))
			
		else:
			var dialogs: Array[String] = ["Bullseye~","Take that!"]
			HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 2",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino2"))

func dialog_building_collapsing() -> void:
	
	var crew_speak: int = randi_range(0,1)
	if crew_speak == 0:
		var who: int = randi_range(0,2)
		if who == 0:
			var dialogs: Array[String] = ["Get away from here!!!","The building is collapsing!"]
			HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 3",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino3"))
			
		else:
			var dialogs: Array[String] = ["Holy shit...","We will die if we stay here, moveeee!!!"]
			HUD_dialog.add_to_buffer_low_prior(Dialog_data.new("Rhino 2",dialogs[randi_range(0,dialogs.size()-1)],color,"rhino2"))


func target_enemy(e: Node3D) -> void:
	if not e:
		return
	e = e as Vehicle_Rigid
	if tank_camera.check_enemy_visibility(e):
		e.update_stencil(2)
		return
	e.update_stencil(1)

func untarget_enemy(e: Node3D) -> void:
	if not e:
		return
	e = e as Vehicle_Rigid
	if e == enemy_locked:
		enemy_locked.gets_disabled.disconnect(untarget_enemy)
		
		var lock = tank_camera.get_closest_enemy_to_mouse(enemy_locked.global_position)
		if lock:
			if enemy_locked == lock:
				lock_on = false
				enemy_locked = null
				HUD_Lock_on.visible = lock_on
				return
				
			enemy_locked = lock
			if enemy_locked.gets_disabled.is_connected(untarget_enemy.bind(enemy_locked)):
				lock_on = false
				enemy_locked = null
				HUD_Lock_on.visible = lock_on
				return
			enemy_locked.gets_disabled.connect(untarget_enemy.bind(enemy_locked))
			lock_on = true
			HUD_Lock_on.visible = lock_on
		else:
			lock_on = false
			enemy_locked = null
			HUD_Lock_on.visible = lock_on
		
		return
		
		lock_on = false
		enemy_locked = null
		HUD_Lock_on.visible = lock_on
