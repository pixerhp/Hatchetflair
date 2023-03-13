extends VBoxContainer

var worlds = ["bojler", "eladó"]
var worlds_text
var new_world
var new_world_popup
# Called when the node enters the scene tree for the first time.
func _ready():
	worlds_text = get_node("Worlds")
	new_world= get_node("Buttons/NewWorld")
	new_world_popup=get_parent().get_node("NewWorldPopup")
	new_world.pressed.connect(self.make_world)
	get_parent().get_node("NewWorldPopup/Okay").pressed.connect(self.confirm_make_world)
	get_parent().get_node("NewWorldPopup/Cancel").pressed.connect(new_world_popup.hide)
	new_world_popup.hide()
	update()

func make_world():
	get_parent().get_node("NewWorldPopup/TextEdit").clear()
	new_world_popup.show()
	pass

func confirm_make_world():
	worlds.append(get_parent().get_node("NewWorldPopup/TextEdit").text)
	update()
	new_world_popup.hide()
	pass

func update():
	if(worlds_text.item_count!=worlds.size()):
			worlds_text.clear()
			for world in worlds:
				worlds_text.add_item(world)
			return
	var i=0
	for world in worlds:
		worlds_text.set_item_text(i,world)
		i+=1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
