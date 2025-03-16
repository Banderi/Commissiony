extends Control

func _process(_delta):
	
	# for the "To finish..." tab, ALL entries are marked as important and thus
	# add up to the badge counter.
	$Header/BtnTODO/Counter.set_count(Global.DATA.lists.get("todo",[]).size())
	
	# for the "Waitlist" tab, only entries that ar marked as important add up.
	var c = 0
	for i in Global.DATA.lists.get("waitlist",[]):
		if int(i.get("flags", 0)) & Global.FLAGS.IMPORTANT:
			c += 1
	$Header/BtnWaitlist/Counter.set_count(c)
	
	# continuously update the "last_tab" user var
	for n in $Header.get_children().size():
		if $Header.get_child(n).pressed:
			if n != Global.SETTINGS.get("last_tab",1):
				Global.set_config("last_tab", n)

var is_loading = true
func load_settings():
	Global.load_settings()
	$Autosave.pressed = Global.SETTINGS.autosave

# Called when the node enters the scene tree for the first time.
func _ready():
	load_settings()
	Global.TEST_PRINT_LABEL = $Panel/TEST
	Global.footer_label = $Panel/Label
	
	Global.list_node = $ScrollContainer/VBoxContainer
	Global.autocomplete = $Autocomplete
	Global.autocomplete_list = $Autocomplete/VBoxContainer
	Global.autocomplete.hide()
	
	Global.delicate_node = $Delicate
	Global.popup_node = $Delicate/ConfirmationDialog
	Global.popup_node.connect("popup_hide", Global, "popup_hidden")
	Global.delicate(false)
	
	$Clipboard.text = ""
	Global.clipboard = $Clipboard
	
	Global.load_data()
	Global.set_unsaved_changes(false)
	is_loading = false
	open_last_tab()

func _input(_event):
	if Input.is_action_just_pressed("close all"): # ctrl + shift + O
		if !Global.all_are_closed:
			for n in Global.list_node.get_children():
				n.toggle(0)
			Global.all_are_closed = true
		else:
			for n in Global.list_node.get_children():
				if n.data != null:
					n.toggle(1)
	if Input.is_action_just_pressed("toggle"): # ctrl + shift + Q
		if Global.last_focused != null:
			Global.last_focused.toggle()
	if Input.is_action_just_pressed("save"):
		Global.save_data()
	if Input.is_action_just_pressed("reload"):
		var _r = get_tree().reload_current_scene()
	if Input.is_action_just_pressed("ui_cancel"):
		Global.popup_node.hide()

func open_last_tab():
	var last_tab = Global.SETTINGS.get("last_tab",1)
	$Header.get_child(last_tab).pressed = true
	$Header.get_child(last_tab).emit_signal("pressed")
func cleartabs():
	for n in $Header.get_children():
		if n.mouse_filter != MOUSE_FILTER_STOP:
			n.pressed = false
			n.mouse_filter = MOUSE_FILTER_STOP
func _on_BtnClipboard_pressed():
	cleartabs()
	$Header/BtnClipboard.mouse_filter = MOUSE_FILTER_IGNORE
	Global.clear_list()
	Global.populate_clipboard()
func _on_BtnPWYW_pressed():
	cleartabs()
	$Header/BtnPWYW.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_list("pwyw")
func _on_BtnTODO_pressed():
	cleartabs()
	$Header/BtnTODO.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_list("todo")
func _on_BtnWaitlist_pressed():
	cleartabs()
	$Header/BtnWaitlist.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_list("waitlist", [], [Global.FLAGS.ON_HOLD])
func _on_BtnOnHold_pressed():
	cleartabs()
	$Header/BtnOnHold.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_list("waitlist", [Global.FLAGS.ON_HOLD])
func _on_BtnUsers_pressed():
	cleartabs()
	$Header/BtnUsers.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_users()
func _on_BtnSettings_pressed():
	cleartabs()
	$Header/BtnSettings.mouse_filter = MOUSE_FILTER_IGNORE
func _on_BtnHistorics_pressed():
	cleartabs()
	$Header/BtnHistorics.mouse_filter = MOUSE_FILTER_IGNORE
	Global.populate_list("old")

func _on_Clipboard_text_changed():
	Global.set_unsaved_changes(true)

func _on_Autosave_toggled(button_pressed):
	if !is_loading:
		Global.set_config("autosave", button_pressed)

func _on_Button_pressed(): # unused, settings button?
	pass # Replace with function body.

