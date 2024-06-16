extends Control

var list = null
var data = {}
var userid = null # this is userid but ONLY used by items in the USERS list!!!!
func update_comm_title_username():
	match list:
		"users":
			$Button.text = userid
			$TextEdit.mouse_filter = MOUSE_FILTER_IGNORE
			$TextEdit.text = ""
		_:
#			var title = $Button.text.split(" ",false,1)
			var title = [data.userid] as PoolStringArray
			var extra = data.get("extra","")
			if extra != "":
				title.push_back(extra)
#			var howmany = 1
#			for n in Global.list_node.get_children():
#				if n == self:
#					break
#				if n.data.get("userid",-1) == data.userid:
#					howmany += 1
#			if howmany > 1:
#				title += "(%d)" % [howmany]
			$Button.text = title.join(" ")
	
func update_data():
	if data == null: # for empty "placeholder" items
		$TextEdit.text = ""
		$Button.text = ""
#		$Button.text = "      [+]"
		$TextEdit.text = ""
#		$Button/LabelDate.text = ""
		$Button/LabelDate.text = "[new]"
#		$Button/LabelDate.text = "[+]"
		$TextEdit/BtnComplete.hide()
		$TextEdit/BtnDelete.hide()
		return
	if list == "users":
		$Button/LabelDate.text = ""
		$TextEdit/BtnComplete.hide()
		$TextEdit/CheckBox.hide()
		hide_title_lineedit()
	else:
		var time = OS.get_datetime_from_unix_time(data.timestamp)
#		$Button/LabelDate.text = "%d/%02d/%02d (%d days ago)" % [
		$Button/LabelDate.text = "%d days ago" % [
			(OS.get_unix_time() - data.timestamp) / 86400
		]
		
		update_comm_title_username()
		$TextEdit.text = data.text
		
#		call_deferred("toggle",data.get("open",0))
		toggle(data.get("open",0))
		$TextEdit/BtnComplete.show()
		$TextEdit/CheckBox.hide()
		match list:
			"todo":
				$TextEdit/BtnComplete.text = "Done"
			"pwyw","waitlist":
				$TextEdit/BtnComplete.text = "Start"
				$TextEdit/CheckBox.show()
				$TextEdit/CheckBox.pressed = bool(data.get("counter", 0))
			"old":
				$TextEdit/BtnComplete.hide()

func _ready():
	get_tree().root.connect("size_changed", self, "resize")
	remove_textedit_scrollbar()
	
	# for some mysterious and ANNOYING reason, the resizing of the box
	# with the wrapped text fails *slightly* if done too soon. so we
	# wait for the next idle frame after spawning...
	yield(get_tree(), "idle_frame")
	update_openclose()

func remove_textedit_scrollbar():
	for child in $TextEdit.get_children():
		if child is VScrollBar:
			$TextEdit.remove_child(child)
		elif child is HScrollBar:
			$TextEdit.remove_child(child)  
	
func focus():
	Global.last_focused = self

func toggle(enabled = -1):
	if enabled == -1:
		$Button.pressed = !$Button.pressed
	else:
		$Button.pressed = bool(enabled) # this calls _on_Button_toggled() which then calls update_openclose()
		if !is_inside_tree():
			call_deferred("update_openclose")
func update_openclose():
	if data != null && list != "users":
		data["open"] = int($Button.pressed)
	$TextEdit.visible = $Button.pressed
#	if list == "users":
#		$Button/LineEdit.visible = true
#	else:
	$Button/LineEdit.visible = $Button.pressed
	$Button/LineEdit.text = ""
	resize()
func spawn_new_item_from_placeholder():
	var new = null
	if list == "users":
		if !Global.DATA.users.has("[new user]"):
			Global.new_user("[new user]")
			new = Global.spawn_list_item({}, "[new user]", list)
	else:
		var d = {
			"userid": "",
			"cost": 0,
			"text": "",
			"timestamp": OS.get_unix_time(),
			"open": 0
		}
		Global.DATA.lists[list].push_back(d)
		new = Global.spawn_list_item(d, null, list)
	if new != null:
		new.call_deferred("toggle",1)
		Global.set_unsaved_changes(true)
	Global.spawn_list_item(null, null, list) # add empty placeholder
	queue_free()
func _on_Button_toggled(button_pressed):
	if !is_inside_tree():
		return
	if data == null:
		return spawn_new_item_from_placeholder()
	Global.all_are_closed = false
	if button_pressed:
		focus()
	update_openclose()
	if data != null && list != "users":
		Global.set_unsaved_changes(true)

func move_to_list(new_list):
	Global.new_list_item(new_list, data)
	Global.delete_list_item(list, data)
	data.timestamp = OS.get_unix_time()
	queue_free()

func confirm_complete():
	move_to_list("old")
func confirm_start():
	move_to_list("todo")
func _on_BtnComplete_pressed():
	match list:
		"todo":
			Global.delicate_popup("", "Set the current slot as complete?", self, "confirm_complete")
		"pwyw","waitlist":
			Global.delicate_popup("", "Start the current slot?", self, "confirm_start")
	
func confirm_delete():
	hide_title_lineedit()
	Global.delete_list_item(list, data)
	queue_free()
func confirm_delete_user():
	hide_title_lineedit()
	Global.delete_user(userid)
	queue_free()
func _on_BtnDelete_pressed():
	if list == "users":
		Global.delicate_popup("", "Are you SURE you want to delete this user?", self, "confirm_delete_user")
	else:
		Global.delicate_popup("", "Delete the current item?", self, "confirm_delete")

onready var FONT = $TextEdit.get("custom_fonts/font")
onready var SPACE_WIDTH = FONT.get_string_size(" ").x
func count_total_lines(text : String):
	var total_lines = 0
	for line in text.split("\n"):
		# minimum for each hard-broken line is "1", obviously.
		var lines_req = 1
		var line_length = 0
		for word in line.split(" "):
			var word_length = FONT.get_string_size(word).x
			
			# if line length exceeds box size, wrap
			line_length += (SPACE_WIDTH + word_length)
			if line_length > $TextEdit.rect_size.x - 12: # accounting for gutters
				lines_req += 1
				line_length = word_length
		
		# add final tally to line counter!
		total_lines += lines_req
	return total_lines
func count_wraps_builtin():
	var carriages = $TextEdit.get_line_count()
	var wraps = carriages
	for c in carriages:
		wraps += $TextEdit.get_line_wrap_count(c)
#	var wrapped = $TextEdit.get_line_wrapped_text()
#	wraps = wrapped.size()
	return wraps
func resize():
	if $TextEdit.visible:
#		var wraps = count_total_lines($TextEdit.text)
		var wraps = count_wraps_builtin()
		$TextEdit.rect_size.y = max(FONT.get_height() * (wraps + 2) + 5, FONT.get_height() * 4 + 5)
	else:
		$TextEdit.rect_size.y = 0
	rect_min_size.y = $TextEdit.rect_size.y + $TextEdit.rect_position.y
func _on_TextEdit_text_changed():
	Global.set_unsaved_changes(true)
	data.text = $TextEdit.text
	resize()
func _on_TextEdit_focus_entered():
	Global.last_focused = self

# username / title edit
var name_edit_lost_focus = false
var new_name_was_entered = false
func _on_LineEdit_focus_entered():
	focus()
	match list:
		"users":
			$Button/LineEdit.text = userid
		_:
			$Button/LineEdit.text = $Button.text
			_on_LineEdit_text_changed($Button/LineEdit.text)
			Global.autocomplete.show()
			Global.autocomplete.rect_position = get_global_rect().position + Vector2(40,21)
	
	$Button.text = ""
	Global.name_currently_editing = self
func _on_LineEdit_focus_exited():
	if !Global.autocomplete.has_focus() && !name_edit_lost_focus:
		if !new_name_was_entered:
			name_edit_lost_focus = true
		new_name_was_entered = false
func hide_title_lineedit():
	$Button/LineEdit.text = ""
	if is_inside_tree():
		$Button/LineEdit.release_focus()
	Global.autocomplete.hide()
	update_comm_title_username()
func _on_LineEdit_text_changed(new_text):
	var split = new_text.split(" ",false,1)
	if split.size() > 0:
		Global.update_autocomplete(split[0])
	else:
		Global.update_autocomplete("")
func _on_LineEdit_text_entered(new_text):
	match list:
		"users":
			if new_text != "" && new_text != userid:
				if Global.change_user_name(userid, new_text):
					userid = new_text
					update_comm_title_username()
			name_edit_lost_focus = true
		_:
			var split = $Button/LineEdit.text.split(" ",false,1)
			if split.size() > 0:
				if split[0] != data.userid: # name change
					new_name_was_entered = true
					change_name("")
				if split.size() < 2:
					change_extra("")
				elif split.size() > 1 && split[1] != data.get("extra",""):
					change_extra(split[1])
			else:
				name_edit_lost_focus = true

func _input(event):
	if name_edit_lost_focus:
		hide_title_lineedit()
		name_edit_lost_focus = false
#	if event is InputEventMouseButton:
#		var SC = Global.list_node.get_parent()
#		if event.button_index == BUTTON_WHEEL_UP:
#			SC._on_redirected_input(event)
#		if event.button_index == BUTTON_WHEEL_DOWN:
#			SC._on_redirected_input(event)
#		if event.button_index == BUTTON_MIDDLE:
#			SC._on_redirected_input(event)
			
func confirm_new_user(new_userid):
	Global.new_user(new_userid)
	data.userid = new_userid
	hide_title_lineedit()
	update_comm_title_username()
func change_name(selected_from_autocomplete): # this assumes that the change WAS VALID and ENTERED
	if selected_from_autocomplete == "":
		var split = $Button/LineEdit.text.split(" ",false,1)
		var new_userid = split[0]
		if !Global.DATA.users.has(new_userid): # create new user
			Global.delicate_popup("", str("Create '",new_userid,"' as a new user?"), self, "confirm_new_user", [new_userid])
		else:
			data.userid = new_userid
			if split.size() > 1:
				data.extra = split[1]
			else:
				data.erase("extra")
			hide_title_lineedit()
			update_comm_title_username()
			Global.set_unsaved_changes(true)
	else:
		if selected_from_autocomplete != data.userid:
			Global.set_unsaved_changes(true)
		data.userid = selected_from_autocomplete
		update_comm_title_username()
func change_extra(new_extra): # this assumes that the change WAS VALID and ENTERED
	if new_extra == "":
		data.erase("extra")
	else:
		data["extra"] = new_extra
	hide_title_lineedit()
	update_comm_title_username()
	Global.set_unsaved_changes(true)
			
func _on_NameOption_pressed(selected_from_autocomplete):
	change_name(selected_from_autocomplete)
	name_edit_lost_focus = true
	
func _on_CheckBox_toggled(button_pressed):
	if !is_inside_tree():
		return
	data["counter"] = int(button_pressed)
	Global.set_unsaved_changes(true)

func _process(delta):
	if list != "users" && data != null && ((data.get("counter",false) && list == "waitlist") || list == "todo"):
		$Button.set("custom_colors/font_color",Color("ffe300"))
		$Button.set("custom_colors/font_color_hover",Color(1,1,1,1))
		$Button.set("custom_colors/font_color_hover_pressed",Color("fbff80"))
		$Button.set("custom_colors/font_color_pressed",Color("ffe300"))
	else:
		$Button.set("custom_colors/font_color",null)
		$Button.set("custom_colors/font_color_hover",null)
		$Button.set("custom_colors/font_color_hover_pressed",null)
		$Button.set("custom_colors/font_color_pressed",null)


func _on_Button2_pressed():
	resize()
	pass # Replace with function body.
