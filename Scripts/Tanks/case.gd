extends RigidBody3D
class_name Case

var time_controller: Time_Controller
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_controller = Time_Controller.INSTANCE


func recoil(pos: Vector3, dir: Vector3) -> void:
	activate()
	global_position = pos
	
	var rot = Vector3(randf_range(-1.0,1.0),randf_range(-1.0,1.0),randf_range(-1.0,1.0))
	var push = Vector3.ZERO.move_toward(dir, 1)
	#push = Vector3(push.x, 0 ,push.z)
	apply_torque_impulse(rot)
	apply_central_force(push)


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func deactivate() -> void:
	visible = false
	#process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
