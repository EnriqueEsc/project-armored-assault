extends Node3D

@onready var turret: Tank_turret = $Turret
var target

var barrel_upper_limit: float = 360
var barrel_lower_limit: float = -360
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	target = get_tree().root.find_child("Tank_Player",true,false)
	turret.barrel_lower_limit = barrel_lower_limit
	turret.barrel_upper_limit = barrel_upper_limit
	turret.turret_turning_speed = 1
	turret.spawn()
	turret.projectile.ignore = [get_parent_node_3d(), get_parent_node_3d().get_parent_node_3d()]
	
	
	Time_Controller.INSTANCE.timeout.connect(shoot)
	Time_Controller.INSTANCE.start(1)

func shoot() -> void:
	turret.shoot()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(target.position)
	turret.rotate_turret_to_point_3d(target.position)


func activate() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	

func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	Time_Controller.INSTANCE.timeout.disconnect(shoot)
	
	print("sexo")
