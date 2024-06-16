extends Button

var userid : String = ""
func _on_NameOption_pressed():
	Global.name_currently_editing._on_NameOption_pressed(userid)
	
