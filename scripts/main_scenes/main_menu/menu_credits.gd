extends Node

@onready var credits_text_node: RichTextLabel = (
	$CreditsUI/ScrollContainer/PanelContainer/HBoxContainer/CreditsText
)

enum {SECTION, NAME, LINK}
# {enum: [body_color, outline_color]}
const default_colors: Dictionary = {
	SECTION: [Color(1,1,1), Color(0.101960, 0.149019, 0.149019)],
	NAME: [Color(0.690196, 0.870588, 0.757450), Color(0.078431, 0.176470, 0.211764)],
	LINK: [Color(0.533333, 0.568627, 0.619607), Color(0.105882, 0.121568, 0.180392)],
}
# Empty Line: [],
# Format 1: [type, content],
# Format 2: [type, content, [custom_body_color, custom_outline_color]],
const developer_credits_data: Array = [
	[SECTION, "~~ Designer & Lead Developer ~~"],
	[NAME, "Pixer H. Pinecone (@pixerhp)", [Color(0.901960, 0.901960, 0.980392), Color(0.192156, 0.168627, 0.341176)]],
	[],
	[SECTION, "~~ Assistant Developers ~~"],
	[NAME, "Jcodefox (\"Fox\")", [Color(1, 0.647058, 0), Color(0.272549, 0.135294, 0.037254)]],
	[NAME, "Stevemc32 (\"Steve\")"],
	[],
	[SECTION, "~~ Available for Playtesting ~~"],
	[NAME, "E<0>"],
	[NAME, "Blitceed"],
	[NAME, "Redstone"],
	[NAME, "LandOcto950 (\"Squid\")"],
	[NAME, "JJJokesalot (\"JJ\")"],
	[],
	[SECTION, "~~ Programs Notably Used ~~"],
	[NAME, "Godot Game Engine"],
	[NAME, "Blender (Modelling)"],
	[NAME, "Aseprite (Pixel Art)"],
	[NAME, "Garageband & FL Studio"],
	[],
	[SECTION, "~~ Special Thanks ~~"],
	[NAME, "Umbrella Land"],
	[NAME, "Matt Bowlby (\"Blue\") (recommending Godot)"],
	[NAME, "Standard Software Developer (\"SSD\")"],
	[NAME, "Zylann (for original debug draw script:)"],
	[LINK, "https://github.com/Zylann/godot_debug_draw"],
	[],
	[NAME, "(various others, inspirations, and you!)", default_colors[SECTION]],
]


func _ready():
	refresh_credits_text()

func refresh_credits_text() -> Error:
	var credits_text: String = ""
	var err: Error = OK
	
	credits_text += "\n[center]"
	
	var use_custom_colors: bool = false
	for content_arr: Array in developer_credits_data:
		match content_arr.size():
			0:
				credits_text += "\n"
				continue
			2:
				use_custom_colors = false
			3:
				use_custom_colors = true
			_:
				push_error("Incorrect content array format. Content array: ", content_arr)
				err = FAILED
				continue
		
		match content_arr[0]:
			SECTION:
				if use_custom_colors:
					credits_text += "[outline_color=#" + content_arr[2][1].to_html() + "]"
					credits_text += "[color=#" + content_arr[2][0].to_html() + "]"
				else:
					credits_text += "[outline_color=#" + default_colors[SECTION][1].to_html() + "]"
					credits_text += "[color=#" + default_colors[SECTION][0].to_html() + "]"
				credits_text += "[font_size=24]"
				credits_text += str(content_arr[1])
				credits_text += "[/font_size]"
				credits_text += "[/color]"
				credits_text += "[/outline_color]"
				credits_text += "\n"
				continue
			NAME:
				credits_text += "[wave]"
				if use_custom_colors:
					credits_text += "[outline_color=#" + content_arr[2][1].to_html() + "]"
					credits_text += "[color=#" + content_arr[2][0].to_html() + "]"
				else:
					credits_text += "[outline_color=#" + default_colors[NAME][1].to_html() + "]"
					credits_text += "[color=#" + default_colors[NAME][0].to_html() + "]"
				credits_text += str(content_arr[1])
				credits_text += "[/color]"
				credits_text += "[/outline_color]"
				credits_text += "[/wave]"
				credits_text += "\n"
				continue
			LINK:
				credits_text += "[wave]"
				if use_custom_colors:
					credits_text += "[outline_color=#" + content_arr[2][1].to_html() + "]"
					credits_text += "[color=#" + content_arr[2][0].to_html() + "]"
				else:
					credits_text += "[outline_color=#" + default_colors[LINK][1].to_html() + "]"
					credits_text += "[color=#" + default_colors[LINK][0].to_html() + "]"
				credits_text += "[url=" + str(content_arr[1]) + "]"
				credits_text += str(content_arr[1])
				credits_text += "[/url]"
				credits_text += "[/color]"
				credits_text += "[/outline_color]"
				credits_text += "[/wave]"
				credits_text += "\n"
				continue
			var unsupported_content_type:
				push_error("Unsupported content type: ", unsupported_content_type)
				err = FAILED
				continue
	
	credits_text += "[/center]\n"
	
	credits_text_node.text = credits_text
	return err

func _on_credits_text_url_clicked(meta):
	OS.shell_open(str(meta))
