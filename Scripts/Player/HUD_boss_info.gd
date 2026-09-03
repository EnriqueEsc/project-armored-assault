extends Control
class_name HUD_Boss_Info

@onready var boss_ap_bar: ProgressBar = $HUD_Boss_AP_Bar
@onready var boss_name_text: RichTextLabel = $HUD_Boss_Name
var is_boss_active = false

var boss_name: String = ""
var boss_max_ap: int = 0
var boss_current_ap: int = 0

func update_AP_Bar(percent: float) -> void:
	boss_ap_bar.value = percent
	if percent <= 0:
		update_boss_active(false)

func update_boss_name(name: String) -> void:
	boss_name = name
	
func update_boss_max_ap(ap: int) -> void:
	boss_max_ap = ap
	
func update_boss_current_ap(ap: int) -> void:
	boss_current_ap = ap
	boss_name_text.text = boss_name+" ["+str(boss_current_ap)+"/"+str(boss_max_ap)+"]"
	if boss_current_ap >= boss_max_ap:
		show_boss_info()

func update_boss_active(b: bool) -> void:
	is_boss_active = b
	show_boss_info()

func show_boss_info() -> void:
	visible = is_boss_active

func color_boss_info(color: Color) -> void:
	boss_ap_bar.modulate = color
	boss_name_text.modulate = color
