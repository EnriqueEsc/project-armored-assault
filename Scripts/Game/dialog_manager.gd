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

func get_current_buffer_size() -> int:
	return player.HUD_dialog.dialog_buffer.size()


func add_text_to_buffer_max_prior(name: String, dialog: String, char_image: String = "default"):
	player.add_text_to_buffer_max_prior(name,dialog,char_image)

func add_text_to_buffer(name: String, dialog: String, char_image: String = "default"):
	player.add_text_to_buffer(name,dialog,char_image)

func add_text_to_buffer_low_prior(name: String, dialog: String, char_image: String = "default"):
	player.add_text_to_buffer_low_prior(name,dialog,char_image)

func display_text(name: String, dialog: String, char_image: String = "default"):
	player.display_text(name,dialog,char_image)

func add_dialog_to_buffer(dialog: Dialog_data):
	player.add_dialog_to_buffer(dialog)

func add_dialog_to_buffer_low_prior(dialog: Dialog_data):
	player.add_dialog_to_buffer_low_prior(dialog)
	
func add_dialog_to_buffer_max_prior(dialog: Dialog_data):
	player.add_dialog_to_buffer_max_prior(dialog)

func display_dialog(dialog: Dialog_data):
	player.display_dialog(dialog)
