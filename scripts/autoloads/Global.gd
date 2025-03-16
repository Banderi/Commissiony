extends Node

var TEST_PRINT_LABEL = null
func TEST_PRNT(txt):
	TEST_PRINT_LABEL.text = str(txt)
	print(txt)

enum FLAGS {
	NORMAL = 0,
	IMPORTANT = 1,
	ON_HOLD = 2
}

onready var item_scn = load("res://scenes/ListItem.tscn")
var list_node = null
var last_focused = null
var all_are_closed = false
func clear_list():
	list_node.show()
	if FORCE_CLEAR:
		for n in list_node.get_children():
			n.queue_free()
	last_focused = null
	clipboard.hide()
	autocomplete.hide()
func spawn_list_item(data, userid, list):
	var item = item_scn.instance()
	item.setup(data, userid, list) # moved everything here!
	list_node.add_child(item)
	return item

const FORCE_CLEAR = true
func populate_list(list : String, flags : Array = [], flags_exclude : Array = []):
	
	clear_list()
	var list_present = list_node.get_children()
	var list_required = DATA.lists.get(list,[])
	var total_present = list_present.size()
	var total_required = list_required.size()
	
	if FORCE_CLEAR:
		for i in list_required:
			
			# check that flags match!
			var i_flags = int(i.get("flags", 0))
			var any_flag_match = false
			if flags != []:
				for f in flags:
					if i_flags & f:
						any_flag_match = true
						break
				if !any_flag_match:
					continue
					
			if flags_exclude != []:
				any_flag_match = false
				for f in flags_exclude:
					if i_flags & f:
						any_flag_match = true
				if any_flag_match:
					continue
			spawn_list_item(i, null, list)
	else:					# An attempt at optimizing by using previous items
		var c = 0			# instead of respawning everything. Not worth it..
		for i in list_required:
			if c < total_present:
				list_present[c].setup(i, null, list)
			else:
				spawn_list_item(i, null, list)
			c += 1
		if c < total_present:
			for i in range(c, total_present):
				list_present[i].queue_free()
	
	if list != "old":
		spawn_list_item(null, null, list) # add empty placeholder
	
func new_list_item(list, item):
	DATA.lists[list].push_back(item)
	set_unsaved_changes(true)
func delete_list_item(list, item):
	DATA.lists[list].erase(item)
	set_unsaved_changes(true)

func populate_users():
	clear_list()
	var ordered_list = DATA.users.keys()
	ordered_list.sort()
	for userid in ordered_list:
		spawn_list_item(DATA.users[userid], userid, "users")
	spawn_list_item(null, null, "users") # add empty placeholder
func new_user(userid):
	DATA.users[userid] = {}
	populate_autocomplete()
	set_unsaved_changes(true)
func delete_user(userid):
	DATA.users.erase(userid)
	populate_autocomplete()
	set_unsaved_changes(true)
func change_user_name(userid, new_userid):
	if DATA.users.has(new_userid):
		delicate_popup("Error", str("User '",new_userid,"' already exists!"), self, null)
		return false
	DATA.users[new_userid] = DATA.users[userid]
	DATA.users.erase(userid)
	populate_autocomplete()
	
	# sigh....
	# this is the downside of having the userlist be populated as a name-keyed dictionary
	# instead of a UUID-indexed database like originally planned. you really can't win.
	for list in DATA.lists.keys():
		for i in DATA.lists[list]:
			if i.userid == userid:
				i.userid = new_userid
	
	set_unsaved_changes(true)
	return true

var autocomplete = null
var autocomplete_list = null
onready var nameoption_scn = load("res://scenes/NameOption.tscn")
func populate_autocomplete():
	for n in autocomplete_list.get_children():
		n.free()
	
	var ordered_list = DATA.users.keys()
	ordered_list.sort()
	for userid in ordered_list:
		var option = nameoption_scn.instance()
		option.text = userid
		option.userid = userid
		autocomplete_list.add_child(option)
	update_autocomplete("")
func update_autocomplete(text):
	var count = 0
	for i in autocomplete_list.get_children():
		if text == "" || text.to_lower() in i.text.to_lower():
			i.show()
			count += 1
		else:
			i.hide()
	autocomplete.rect_min_size.y = 16 * count + 7
	autocomplete.rect_size.y = 16 * count + 7

var clipboard = null
func populate_clipboard():
	clipboard.text = DATA.get("clipboard","")
	clipboard.show()

var footer_label = null
func footer_text(text):
	footer_label.text = text
	t = 0
var t = 0
func _process(delta):
	t += delta
	if t > 2:
		footer_label.text = ""
	if SETTINGS.autosave && unsaved_changes:
		save_data()
	if t >= 5:
#		print("Datestamp update")
		t = 0
		for n in get_tree().get_nodes_in_group("time_update"):
			n.update_date_stamp_label()
	
func save_settings():
	if !IO.write("user://SETTINGS.json", JSON.print(SETTINGS,"\t")):
		footer_text("Could not save data to disk!")
func load_settings():
	var r_settings = IO.read("user://SETTINGS.json", true)
	if r_settings != null:
		SETTINGS = JSON.parse(r_settings).get_result()
	else: # no settings file
		save_settings()
func set_config(config, value):
	SETTINGS[config] = value
	save_settings()

func sort_by_timestamp(a, b):
	return a.timestamp < b.timestamp

func save_data():
	DATA["clipboard"] = clipboard.text
	if IO.write("user://DATA.json", JSON.print(DATA,"\t")):
		set_unsaved_changes(false)
		footer_text("Saved!")
	else:
		footer_text("Could not save data to disk!")
func load_data():
	var r_data = IO.read("user://DATA.json", true)
	if r_data != null:
		DATA = JSON.parse(r_data).get_result()
		footer_text("Data loaded successfully!")
		set_unsaved_changes(false)
	else:
		footer_text("Could not load data!")
		save_data()
	
	# CONVERT OLD DATA FORMAT...
#	for l in DATA.lists:
#		for i in DATA.lists[l]:
#			DATA.lists[l][i]["username"] = i
#			DATA.lists[l][i].erase("userid")
	for l in DATA.lists:
		for i in DATA.lists[l].size():
			DATA.lists[l][i]["userid"] = str(DATA.lists[l][i]["userid"])
		DATA.lists[l].sort_custom(self, "sort_by_timestamp")
	if DATA.users is Array:
		var new_users : Dictionary = {}
		for u in DATA.users.size():
			new_users[str(u)] = DATA.users[u]
		DATA.users = new_users
	
	populate_autocomplete()
	populate_clipboard()
var unsaved_changes = false
func set_unsaved_changes(yes):
	if yes:
		unsaved_changes = true
		OS.set_window_title("Commissiony*")
	else:
		unsaved_changes = false
		OS.set_window_title("Commissiony")

var DATA = {
	#...
	"lists": {
		"pwyw":[],
		"todo":[],
		"waitlist":[],
		"old":[],
	},
	"users": {
	},
	"clipboard":""
}
var SETTINGS = {
	"autosave":false
}

var delicate_node = null
var popup_node = null
#signal popup_confirmed
func delicate_popup(title, text, node, callback, args = []):
	delicate(true)
	popup_node.window_title = title
	popup_node.dialog_text = text
	if callback != null:
		popup_node.connect("confirmed", node, callback, args)
	popup_node.popup()
func delicate(on):
	delicate_node.visible = on
func popup_hidden():
	for c in popup_node.get_signal_connection_list("confirmed"):
		popup_node.call_deferred("disconnect", "confirmed", c.target, c.method)
	delicate(false)

var name_currently_editing = null
