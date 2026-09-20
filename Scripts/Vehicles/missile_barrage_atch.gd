extends Attachment

var case_prefab = preload("res://Prefabs/Test/missile_he.tscn")
var case: Missile

var case_pool: Array[Missile] = []
var case_active: Array[Missile] = []

func _ready() -> void:
	await get_tree().physics_frame
	create_projectiles()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _attachment_function() -> void:
	
	for i in 5:
		
		var case: Missile
		if case_pool.size() <= 0:
			case = case_active.pop_front()
		else:
			case = case_pool.pop_front()
		if case:
			case_active.push_back(case)
			case.objective = objective
			case.shoot(Vector3(global_position.x, global_position.y,global_position.z),Vector2(90,-30))
			#case.recoil(global_position, -global_basis.z)
		
		shakes.emit(0.1,0.2)
		
		await get_tree().create_timer(0.2).timeout
	pass



func create_projectiles() -> void:
	for i in 10:
		case = case_prefab.instantiate() as Missile
		case.set_origin(get_parent_node_3d() as Vehicle_Rigid)
		case.deactivate()
		case.deactivated.connect(case_to_pool)
		get_tree().current_scene.call_deferred("add_child",case)
		#get_tree().current_scene.add_child(case)
		case_pool.append(case)

func case_to_pool(current_case: Missile) -> void:
	case_active.erase(current_case)
	case_pool.push_back(current_case)
	#current_projectile.deactivate()
