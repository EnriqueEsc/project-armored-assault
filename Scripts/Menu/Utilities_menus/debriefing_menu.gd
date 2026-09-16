extends Menu

@onready var briefing_text: Typing_Text = $Mission_Briefing/Briefing_text
@onready var to_menu_button: Button = $Mission_Briefing/To_Main_Menu

var debriefing_finished: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	to_menu_button.pressed.connect(get_tree().change_scene_to_file.bind("res://Scenes/main_menu.tscn"))
	to_menu_button.visible = debriefing_finished
	briefing_text.finished_typing.connect(finish_debrief)
	briefing_text.set_process(true)
	
	var text_to_show = "Mission completed succesfully
....
....
....
STATS:
"
	var results: Dictionary = Save_File_Manager.INSTANCE.LAST_MISSION_RESULTS
	for v in results:
		text_to_show += "%s : %s\n\n" % [v,results[v]]
	
	briefing_text.set_text_to_type(text_to_show)

func finish_debrief() -> void:
	debriefing_finished = true
	to_menu_button.visible = debriefing_finished
