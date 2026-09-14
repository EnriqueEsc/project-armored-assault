extends RefCounted
class_name Dialog_data

var name: String = ""
var dialog: String = ""
var color: Color = Color.WHITE
var char_image: Texture = null

func _init(name: String, dialog: String, color: Color, char_image: String = "default") -> void:
	self.name = name
	self.dialog = dialog
	self.color = color
	self.char_image = load("res://Sprites/Characters/"+char_image+".png") as Texture
