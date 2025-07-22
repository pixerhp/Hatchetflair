extends CanvasLayer

var canvas_item: CanvasItem = null

var texts_to_draw: PackedStringArray = []
var texts_font: Font = ThemeDB.fallback_font
var texts_color: Color = Color.WHITE
var texts_ypad: int = 0
var texts_do_back: bool = true
var texts_back_color: Color = Color(0.0833, 0.0833, 0.0833, 0.75)

func _ready():
	canvas_item = Node2D.new()
	canvas_item.position = Vector2(8, 8)
	canvas_item.connect("draw", _on_CanvasItem_draw)
	add_child(canvas_item)

func _process(_delta):
	texts_to_draw.append("test " + str(randi()))
	texts_to_draw.append("test " + str(randi()))
	texts_to_draw.append("test " + str(randi()))
	canvas_item.queue_redraw()

func _on_CanvasItem_draw():
	# Handle debug texts:
	var draw_pos: Vector2 = Vector2()
	var font_ascent: Vector2 = Vector2(0, texts_font.get_ascent())
	var font_height: int = texts_font.get_height() + texts_ypad
	for string in texts_to_draw:
		if texts_do_back:
			canvas_item.draw_rect(Rect2(
				draw_pos, Vector2(texts_font.get_string_size(string).x, font_height)
			), texts_back_color)
		canvas_item.draw_string(
			texts_font, draw_pos + font_ascent, string, 
			HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeDB.fallback_font_size, texts_color,
		)
		draw_pos.y += font_height
	texts_to_draw.clear()
