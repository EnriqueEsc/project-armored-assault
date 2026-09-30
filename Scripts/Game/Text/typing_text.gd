extends RichTextLabel
class_name Typing_Text

var text_to_type: String = ""
var current_text: String = ""
var buffer = []
var additional_tags: String = "[color=green]"

var click_count: int = 0

var timer = Timer.new()

signal finished_typing()

var skip_text: RichTextLabel = null
@export var min_clicks_to_skip: int = 1

func _ready() -> void:
	current_text = ""
	text = ""
	
	timer.wait_time = 0.05
	timer.one_shot = false
	timer.timeout.connect(type_text)
	add_child(timer)
	
	
	set_process(false)
	
	if skip_text:
		return
	
	
	for c in get_children():
		if skip_text:
			continue
		if c is RichTextLabel:
			skip_text = c
			finished_typing.connect(show_skip_text.bind(false))
			show_skip_text(true)

func show_text(activated: bool) -> void:
	visible = activated

func _process(delta: float) -> void:
	if not visible:
		return
	
	if Input.is_action_just_pressed("Pause_menu"):
		break_typing()
		get_parent_control().visible = false
	
	if Input.is_action_just_pressed("Shoot"):
		click_count += 1
		if click_count > min_clicks_to_skip:
			stop_typing()

func break_typing() -> void:
		stop_typing()
		text = ""

func stop_typing() -> void:
	timer.stop()
	text = additional_tags + text_to_type
	finished_typing.emit()

func start_typing() -> void:
	click_count = 0
	timer.start()

func set_text_to_type(s: String) -> void:
	text_to_type = s
	buffer = Array(s.split())
	text = ""
	current_text = ""
	start_typing()

func type_text() -> void:
	if buffer.is_empty():
		text = additional_tags + current_text
		return
	
	var next_letter = buffer.pop_front()
	current_text += next_letter
	
	text = additional_tags + current_text + "_"
	
	if buffer.is_empty():
		finished_typing.emit()

func show_skip_text(b: bool) -> void:
	if not skip_text:
		return
	skip_text.visible = b
