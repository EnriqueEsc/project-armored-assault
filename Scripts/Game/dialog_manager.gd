extends Node
class_name Dialog_Manager

static var INSTANCE: Dialog_Manager = null
var player: Tank_player_controller = null

func _ready() -> void:
	singleton()
	
func singleton() -> void:
	if(Effects_Manager.INSTANCE != null):
		queue_free()
		return
	Dialog_Manager.INSTANCE = self

func add_text_to_buffer(name: String, dialog: String):
	player.add_text_to_buffer(name,dialog)


func display_text(name: String, dialog: String):
	player.display_text(name,dialog)

func add_dialog_to_buffer(dialog: Dialog_data):
	player.add_dialog_to_buffer(dialog)

func display_dialog(dialog: Dialog_data):
	player.display_dialog(dialog)
