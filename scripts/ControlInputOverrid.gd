extends ScrollContainer

onready var SB = get_v_scrollbar()
func _ready():
#	SB.custom_step = -0.0001
	connect("gui_input", SB, "_gui_input")

func redirect_input(event):
	emit_signal("gui_input", event)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			redirect_input(event)
		if event.button_index == BUTTON_WHEEL_DOWN:
			redirect_input(event)
		if event.button_index == BUTTON_MIDDLE:
			event.button_index = BUTTON_LEFT
#			event.position.y = (SB.value / max(SB.max_value, 1.0))
#			event.position = SB.get_local_mouse_position()
			redirect_input(event)
#			event.button_index = BUTTON_MIDDLE
	
	if Input.is_action_pressed("mmb"):
		if event is InputEventMouseMotion:
#			event.position.y = (SB.value / max(SB.max_value, 1.0))
			redirect_input(event)
