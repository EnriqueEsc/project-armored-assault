extends Control
class_name HUD_Dialog

@onready var dialog_name: RichTextLabel = $Dialog_Name
@onready var dialog_text: Typing_Text = $Dialog_Text
@onready var dialog_sprite: Sprite2D = $Dialog_Sprite

var screen_time: float = 3.0
var time_active: float = 0.0

var dialog_buffer: Array[Dialog_data] = []
var is_typing: bool = false

var is_active: bool = false

var mission_started: bool = false

var low_prior_buffer: Array[Dialog_data] = []

var using_low_prior: bool = false

func _ready() -> void:
	dialog_text.additional_tags = ""
	dialog_text.finished_typing.connect(finished_typing)
	is_active = false
	visible = is_active
	set_process(false)

func _process(delta: float) -> void:
	time_active += delta
	
	if time_active > screen_time:
		set_process(false)
		
		if not dialog_buffer.is_empty():
			display_dialog(dialog_buffer.pop_front())
			if dialog_buffer.size() > 0:
				using_low_prior = false
			else:
				using_low_prior = true
		elif using_low_prior and not low_prior_buffer.is_empty():
			display_dialog(low_prior_buffer.pop_back())
			using_low_prior = false
			low_prior_buffer.clear()
		else:
			low_prior_buffer.clear()
			is_active = false
			visible = is_active
			is_typing = false

func display_dialog(dialog: Dialog_data) -> void:
	#print("DISPLAY")
	dialog_name.modulate = dialog.color
	dialog_text.modulate = dialog.color
	dialog_sprite.texture = dialog.char_image
	dialog_sprite.modulate = dialog.color
	
	dialog_name.text = dialog.name
	
	is_active = true
	visible = is_active
	dialog_text.set_text_to_type(dialog.dialog)
	is_typing = true

func finished_typing() -> void:
	set_process(true)
	is_typing = false
	time_active = 0.0

func add_to_buffer(dialog: Dialog_data) -> void:
	if not visible:
		if not mission_started:
			dialog_buffer.append(dialog)
			return
		display_dialog(dialog)
	else:
		dialog_buffer.append(dialog)
	#low_prior_buffer.clear()

func add_to_buffer_low_prior(dialog: Dialog_data) -> void:
	#if low_prior_buffer.size() > 0:
	#	return
	low_prior_buffer.append(dialog)
	if is_typing or is_active:
		using_low_prior = false
		return
	if dialog_buffer.size() < 1:
		display_dialog(low_prior_buffer.pop_back())
		using_low_prior = true
		#low_prior_buffer.clear()
		#low_prior_buffer.clear()
	
	if dialog_buffer.size() > 1:
		using_low_prior = false


func start_mission() -> void:
	mission_started = true
	if not dialog_buffer.is_empty():
		display_dialog(dialog_buffer.pop_front())
