extends CanvasLayer

var line_material: StandardMaterial3D = StandardMaterial3D.new()

var lines_mesh_instance: MeshInstance3D = MeshInstance3D.new()
var lines_immediate_mesh: ImmediateMesh = ImmediateMesh.new()
var lines_to_draw: Array[Array] = [] # Expects each line as: [Vector3, Vector3, Color (optional)]

@onready var cam_node: Node = get_tree().current_scene.find_child("FlyCam")
var borders_draw_mode: int = 0
var chunkborders_mesh_instance: MeshInstance3D = MeshInstance3D.new()
var chunkborders_arraymesh: ArrayMesh = ArrayMesh.new()
var chunkborders_move_with_cam: bool = false
var metringrid_mesh_instance: MeshInstance3D = MeshInstance3D.new()
var metringrid_arraymesh: ArrayMesh = ArrayMesh.new()
var metringrid_move_with_cam: bool = false

var texts_canvas_item: CanvasItem = null
var texts_draw_mode: bool = false
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
	
	lines_mesh_instance.mesh = lines_immediate_mesh
	lines_mesh_instance.material_override = line_material
	lines_mesh_instance.name = "LinesMeshInstance"
	add_child(lines_mesh_instance)
	
	texts_canvas_item = Node2D.new()
	texts_canvas_item.position = Vector2(8, 8)
	texts_canvas_item.connect("draw", _on_texts_canvasitem_draw)
	texts_canvas_item.visible = true
	texts_canvas_item.name = "TextsCanvasItem"
	add_child(texts_canvas_item)
	
	initialize_chunkborders_arraymesh()
	chunkborders_mesh_instance.mesh = chunkborders_arraymesh
	chunkborders_mesh_instance.material_override = line_material
	chunkborders_mesh_instance.visible = false
	chunkborders_mesh_instance.name = "ChunkBordersMeshInstance"
	add_child(chunkborders_mesh_instance)
	
	initialize_metringrid_arraymesh()
	metringrid_mesh_instance.mesh = metringrid_arraymesh
	metringrid_mesh_instance.material_override = line_material
	metringrid_mesh_instance.visible = false
	metringrid_mesh_instance.name = "MetrinGridMeshInstance"
	add_child(metringrid_mesh_instance)

const chunk_length: int = 16 # (assumes metrin is length 1.)
func initialize_chunkborders_arraymesh():
	const layers: int = 3
	const grid_close_hue: float = 3.5 / 6.0
	const grid_color_range: float = 0.5 / 6.0
	
	var verts: PackedVector3Array = []
	verts.resize((layers*2)**3)
	var colors: PackedColorArray = []
	colors.resize((layers*2)**3)
	var indices: PackedInt32Array = []
	indices.resize(2 * int( # number of connections (lines) in a cubic grid with n layers:
		(pow((2 * layers) - 1, 3) * 3) + 
		(3 * pow((2 * layers) - 1, 2) * 2) + 
		(3 * ((2 * layers) - 1))
	))
	
	var near_vert_dist: float = pow(3*((0.5 * float(chunk_length)) ** 2), 0.5)
	var far_vert_dist: float = pow(3*(((float(layers) - 0.5) * float(chunk_length)) ** 2), 0.5)
	
	var ind_i: int = 0
	for i in range((layers*2)**3):
		verts[i] = Vector3(
			float(chunk_length) * (posmod(i, layers*2) - (layers - 0.5)), 
			float(chunk_length) * (posmod(i/(layers*2), layers*2) - (layers - 0.5)), 
			float(chunk_length) * (posmod(i/((layers*2)**2), layers*2) - (layers - 0.5)),
		)
		colors[i] = Color.from_hsv(
			fposmod(grid_close_hue + ((verts[i].length() - near_vert_dist) * 
			(grid_color_range / (far_vert_dist - near_vert_dist))), 1),
			1, 1,
		)
		if not posmod(i, layers*2) == (layers*2) - 1:
			indices[ind_i] = i
			indices[ind_i + 1] = i + 1
			ind_i += 2
		if not posmod(i/(layers*2), layers*2) == (layers*2) - 1:
			indices[ind_i] = i
			indices[ind_i + 1] = i + (layers*2)
			ind_i += 2
		if not posmod(i/((layers*2)**2), layers*2) == (layers*2) - 1:
			indices[ind_i] = i
			indices[ind_i + 1] = i + ((layers*2)**2)
			ind_i += 2
	
	# !!! (add center chunk highlight stuff like in the original, around here?)
	
	var surface: Array = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_COLOR] = colors
	surface[Mesh.ARRAY_INDEX] = indices
	
	chunkborders_arraymesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_LINES,
		surface,
	)
func initialize_metringrid_arraymesh():
	const metrin_lines_color: Color = Color.SPRING_GREEN
	
	var verts: PackedVector3Array = []
	verts.resize(12 * (chunk_length - 1))
	var colors: PackedColorArray = []
	colors.resize(12 * (chunk_length - 1))
	var indices: PackedInt32Array = []
	indices.resize(12 * (chunk_length - 1))
	
	var vert_i: int = 0
	var ind_i: int = 0
	
	var x_state: bool = false
	var y_state: bool = false
	var z_state: bool = false
	for i in range(12):
		x_state = int((i == 2) or (i == 5) or (i == 7) or (i == 10))
		y_state = int((i == 3) or (i == 6) or (i == 7) or (i == 11))
		z_state = int((i == 8) or (i == 9) or (i == 10) or (i == 11))
		for j in range(chunk_length - 1):
			match posmod(j, 4):
				0, 2:
					colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.2, 0.2)
				1:
					colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.4, 0.4)
				3:
					colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.8, 0.8)
		if (i == 0) or (i == 3) or (i == 8) or (i == 11): # x row
			for j in range(1, chunk_length, 1):
				verts[vert_i] = Vector3(
					float(j) - (float(chunk_length) / 2.0),
					float(int(y_state) * chunk_length) - (float(chunk_length) / 2.0),
					float(int(z_state) * chunk_length) - (float(chunk_length) / 2.0),
				)
				if y_state == false:
					indices.append_array([vert_i, vert_i + 
					(3 * (chunk_length - 1))])
					ind_i += 1
				if z_state == false:
					indices.append_array([vert_i, vert_i + 
					(8 * (chunk_length - 1))])
					ind_i += 1
				vert_i += 1
		elif (i == 1) or (i == 2) or (i == 9) or (i == 10): # y row
			for j in range(1, chunk_length, 1):
				verts[vert_i] = Vector3(
					float(int(x_state) * chunk_length) - (float(chunk_length) / 2.0),
					float(j) - (float(chunk_length) / 2.0),
					float(int(z_state) * chunk_length) - (float(chunk_length) / 2.0),
				)
				if x_state == false:
					indices.append_array([vert_i, vert_i + 
					(1 * (chunk_length - 1))])
					ind_i += 1
				if z_state == false:
					indices.append_array([vert_i, vert_i + 
					(8 * (chunk_length - 1))])
					ind_i += 1
				vert_i += 1
		elif (i == 4) or (i == 5) or (i == 6) or (i == 7): # z row
			for j in range(1, chunk_length, 1):
				verts[vert_i] = Vector3(
					float(int(x_state) * chunk_length) - (float(chunk_length) / 2.0),
					float(int(y_state) * chunk_length) - (float(chunk_length) / 2.0),
					float(j) - (float(chunk_length) / 2.0),
				)
				if x_state == false:
					indices.append_array([vert_i, vert_i + 
					(1 * (chunk_length - 1))])
					ind_i += 1
				if y_state == false:
					indices.append_array([vert_i, vert_i + 
					(2 * (chunk_length - 1))])
					ind_i += 1
				vert_i += 1
	
	var surface: Array = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_COLOR] = colors
	surface[Mesh.ARRAY_INDEX] = indices
	
	metringrid_arraymesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_LINES,
		surface,
	)

func _process(_delta):
	# Handle DebugDraw related inputs:
	if Input.is_action_just_pressed("debug_info"):
		texts_draw_mode = not texts_draw_mode
	if Input.is_action_just_pressed("debug_borders"):
		borders_draw_mode = posmod(borders_draw_mode + 1, 4)
		match borders_draw_mode:
			0:
				metringrid_mesh_instance.visible = false
				metringrid_move_with_cam = false
			1:
				chunkborders_mesh_instance.visible = true
				chunkborders_move_with_cam = true
			2:
				metringrid_mesh_instance.visible = true
				metringrid_move_with_cam = true
			3:
				chunkborders_mesh_instance.visible = false
				chunkborders_move_with_cam = false
	
	lines_immediate_mesh.clear_surfaces()
	if not lines_to_draw.is_empty():
		draw_lines()
	texts_canvas_item.queue_redraw()

func _physics_process(_delta):
	if not borders_draw_mode == 0:
		var updated_position: Vector3 = (floor((cam_node.position + 
			Vector3(float(chunk_length)/2.0, float(chunk_length)/2.0, float(chunk_length)/2.0)) / 
			float(chunk_length)) * float(chunk_length)
		)
		if chunkborders_move_with_cam:
			chunkborders_mesh_instance.position = updated_position
		if metringrid_move_with_cam:
			metringrid_mesh_instance.position = updated_position

# Assumes line format: [Vector3, Vector3, Color (optional)]
func draw_lines():
	if lines_mesh_instance.visible:
		lines_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for line in lines_to_draw:
			if line.size() > 2:
				lines_immediate_mesh.surface_set_color(line[2])
			else:
				lines_immediate_mesh.surface_set_color(Color.WHITE)
			lines_immediate_mesh.surface_add_vertex(line[0])
			lines_immediate_mesh.surface_add_vertex(line[1])
		lines_immediate_mesh.surface_end()
	lines_to_draw.clear()

func _on_texts_canvasitem_draw():
	# Draw debug texts:
	if texts_draw_mode:
		var draw_pos: Vector2 = Vector2()
		var font_ascent: Vector2 = Vector2(0, texts_font.get_ascent())
		var font_height: float = texts_font.get_height() + texts_ypad
		for string in texts_to_draw:
			if texts_do_back:
				texts_canvas_item.draw_rect(Rect2(
					draw_pos, Vector2(texts_font.get_string_size(string).x, font_height)
				), texts_back_color)
			texts_canvas_item.draw_string(
				texts_font, draw_pos + font_ascent, string, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeDB.fallback_font_size, texts_color,
			)
			draw_pos.y += font_height
	texts_to_draw.clear()
