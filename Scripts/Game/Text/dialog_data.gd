extends RefCounted
class_name Dialog_data

var name: String = ""
var dialog: String = ""
var color: Color = Color.WHITE

func _init(name: String, dialog: String, color: Color) -> void:
	self.name = name
	self.dialog = dialog
	self.color = color
