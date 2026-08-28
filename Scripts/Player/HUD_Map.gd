extends TextureRect
class_name Map_Visualization

@onready var viewport: SubViewport = $SubViewport

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	#var timer = Timer.new()
	#timer.wait_time = 5.0
	#timer.one_shot = false
	#timer.timeout.connect(update_map)
	#add_child(timer)
	#timer.start()
	pass


func update_map() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
