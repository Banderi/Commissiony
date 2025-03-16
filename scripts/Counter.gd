tool
extends Label

func set_count(t):
	text = str(int(t))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if int(text) > 0:
		show()
	else:
		hide()
