extends Timer
class_name Time_Controller

static var INSTANCE: Time_Controller = null
var running_time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton()



func _process(delta: float) -> void:
	running_time += delta
	pass


func singleton() -> void:
	if(Time_Controller.INSTANCE != null):
		queue_free()
		return
	Time_Controller.INSTANCE = self
