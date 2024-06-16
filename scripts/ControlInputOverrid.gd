extends ScrollContainer

func _ready():
	connect("gui_input", get_v_scrollbar(), "_gui_input")

func _on_redirected_input(event):
	emit_signal("gui_input", event)
