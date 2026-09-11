extends Control
class_name HUD_Dialog

@onready var dialog_name: RichTextLabel = $Dialog_Name
@onready var dialog_text: Typing_Text = $Dialog_Text
@onready var dialog_sprite: Sprite2D = $Dialog_Sprite

var screen_time: float = 3.0
var time_active: float = 0.0

var dialog_buffer: Array[Dialog_data] = []
var is_typing: bool = false

func _ready() -> void:
	dialog_text.additional_tags = ""
	dialog_text.finished_typing.connect(finished_typing)
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	time_active += delta
	
	if time_active > screen_time:
		set_process(false)
		
		if not dialog_buffer.is_empty():
			# Hay más diálogos, sacamos el siguiente (visible ya es true)
			display_dialog(dialog_buffer.pop_front())
		else:
			visible = false
			is_typing = false

func display_dialog(dialog: Dialog_data) -> void:
	#print("DISPLAY")
	dialog_name.modulate = dialog.color
	dialog_text.modulate = dialog.color
	dialog_sprite.modulate = dialog.color
	
	dialog_name.text = dialog.name
	
	visible = true
	dialog_text.set_text_to_type(dialog.dialog)
	is_typing = true

func finished_typing() -> void:
	set_process(true)
	is_typing = false
	time_active = 0.0

func add_to_buffer(dialog: Dialog_data) -> void:
	if not visible:
		display_dialog(dialog)
	else:
		dialog_buffer.append(dialog)
