extends CanvasLayer

var canvas_item: CanvasItem = null
var mesh_instance: MeshInstance3D = MeshInstance3D.new()
var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
var line_material: StandardMaterial3D = StandardMaterial3D.new()

var chunkborders_verts: PackedVector3Array = PackedVector3Array()
var chunkborders_indices: PackedInt32Array = PackedInt32Array()
var chunkborders_colors: PackedColorArray = PackedColorArray()

# Expects each outer element to be in the form [Vector3, Vector3, Color]
var lines_to_draw: Array[Array] = []

var texts_to_draw: PackedStringArray = []
var texts_font: Font = ThemeDB.fallback_font
var texts_color: Color = Color.WHITE
var texts_ypad: float = 0
var texts_do_back: bool = true
var texts_back_color: Color = Color(0.0833, 0.0833, 0.0833, 0.75)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	line_material.flags_unshaded = true
	line_material.vertex_color_use_as_albedo = true
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = line_material
	add_child(mesh_instance)
	
	canvas_item = Node2D.new()
	canvas_item.position = Vector2(8, 8)
	canvas_item.connect("draw", _on_CanvasItem_draw)
	add_child(canvas_item)

func _process(_delta):
	immediate_mesh.clear_surfaces()
	draw_chunk_borders()
	if not lines_to_draw.is_empty():
		draw_lines()
	canvas_item.queue_redraw()

func draw_chunk_borders():
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_set_color(Color(1, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(-10, -10, -10))
	immediate_mesh.surface_add_vertex(Vector3(10, 10, 10))
	immediate_mesh.surface_end()

func draw_lines():
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for line in lines_to_draw:
		if line.size() > 2:
			immediate_mesh.surface_set_color(line[2])
		else:
			immediate_mesh.surface_set_color(Color.WHITE)
		immediate_mesh.surface_add_vertex(line[0])
		immediate_mesh.surface_add_vertex(line[1])
	immediate_mesh.surface_end()
	lines_to_draw.clear()

func _on_CanvasItem_draw():
	# Draw debug texts:
	var draw_pos: Vector2 = Vector2()
	var font_ascent: Vector2 = Vector2(0, texts_font.get_ascent())
	var font_height: float = texts_font.get_height() + texts_ypad
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
