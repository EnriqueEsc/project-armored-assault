extends RichTextLabel
class_name Typing_Text

var text_to_type: String = ""
var current_text: String = ""
var buffer = []

var timer = Timer.new()

func _ready() -> void:
	current_text = ""
	text = ""
	
	timer.wait_time = 0.05
	timer.one_shot = false
	timer.timeout.connect(type_text)
	add_child(timer)
	

func show_text(activated: bool) -> void:
	visible = activated

func _process(delta: float) -> void:
	if not visible:
		return
	
	if Input.is_action_just_pressed("Pause_menu"):
		break_typing()
		get_parent_control().visible = false
	
	if Input.is_action_just_pressed("Shoot"):
		stop_typing()

func break_typing() -> void:
		stop_typing()
		text = ""

func stop_typing() -> void:
	timer.stop()
	text = "[color=green]" + text_to_type

func start_typing() -> void:
	timer.start()

func set_text_to_type(s: String) -> void:
	text_to_type = s
	buffer = Array(s.split())
	current_text = ""
	start_typing()

func type_text() -> void:
	if buffer.is_empty():
		text = "[color=green]" + current_text
		return
	
	var next_letter = buffer.pop_front()
	current_text += next_letter
	
	text = "[color=green]" + current_text + "_"
