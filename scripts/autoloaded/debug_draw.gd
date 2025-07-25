extends CanvasLayer

var canvas_item: CanvasItem = null
var general_mesh_instance: MeshInstance3D = MeshInstance3D.new()
var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
var line_material: StandardMaterial3D = StandardMaterial3D.new()

var chunkborders_arraymesh: ArrayMesh = ArrayMesh.new()
var chunkborders_mesh_instance: MeshInstance3D = MeshInstance3D.new()

#var chunkborders_verts: PackedVector3Array = PackedVector3Array()
#var chunkborders_indices: PackedInt32Array = PackedInt32Array()
#var chunkborders_colors: PackedColorArray = PackedColorArray()

# Expects each outer element to be in the form [Vector3, Vector3, Color (optional)]
var lines_to_draw: Array[Array] = []

var texts_to_draw: PackedStringArray = []
var texts_font: Font = ThemeDB.fallback_font
var texts_color: Color = Color.WHITE
var texts_ypad: float = 0
var texts_do_back: bool = true
var texts_back_color: Color = Color(0.0833, 0.0833, 0.0833, 0.75)

@onready var cam_node: Node = get_tree().current_scene.find_child("FlyCam")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	line_material.flags_unshaded = true
	line_material.vertex_color_use_as_albedo = true
	
	general_mesh_instance.mesh = immediate_mesh
	general_mesh_instance.material_override = line_material
	add_child(general_mesh_instance)
	
	canvas_item = Node2D.new()
	canvas_item.position = Vector2(8, 8)
	canvas_item.connect("draw", _on_CanvasItem_draw)
	add_child(canvas_item)
	
	initialize_chunkborders_arraymesh()
	chunkborders_mesh_instance.mesh = chunkborders_arraymesh
	chunkborders_mesh_instance.material_override = line_material
	add_child(chunkborders_mesh_instance)

const chunk_length: int = 16 # (assumes a metrin is length 1.)
func initialize_chunkborders_arraymesh():
	const layers: int = 3
	const grid_close_hue: float = 3.5 / 6.0
	const grid_color_range: float = 0.5 / 6.0
	const metrin_lines_color: Color = Color.SPRING_GREEN
	
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
	
	# !!! (divide the center chunk borders into metrin lines at the walls)
	if chunk_length > 1:
		
		var vert_i: int = verts.size()
		verts.resize(verts.size() + (12 * (chunk_length - 1)))
		colors.resize(colors.size() + (12 * (chunk_length - 1)))
		indices.resize(indices.size() + (6 * (chunk_length - 1) * 2))
		
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
						colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.25, 0.25)
					1:
						colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.5, 0.5)
					3:
						colors[vert_i + j] = Color.from_hsv(metrin_lines_color.h, 0.75, 0.75)
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
			
			
			
			#cnn
			#ncn
			#pcn
			#cpn
			#
			#nnc
			#pnc
			#npc
			#ppc
			#
			#cnp
			#ncp
			#pcp
			#cpp
			pass
		
		#for z in range(chunk_length + 1):
			#for y in range(chunk_length + 1):
				#for x in range(chunk_length + 1):
					#if ((y == 0) or (y == chunk_length)) and ((z == 0) or (z == chunk_length)):
						#verts[ind] = Vector3(
							#float(x) - (float(chunk_length) / 2.0),
							#float(y) - (float(chunk_length) / 2.0),
							#float(z) - (float(chunk_length) / 2.0),
						#)
						#print(verts[ind])
						#colors[ind] = Color.from_hsv(grid_close_hue, 1, 1)
						#indices.append_array([ind, ind + chunk_length])
						#ind += 1
		
		# !!! ...
	
	
	# !!! (add center chunk highlight stuff like in the original, around here.)
	
	var surface: Array = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_COLOR] = colors
	surface[Mesh.ARRAY_INDEX] = indices
	
	chunkborders_arraymesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_LINES,
		surface,
	)
	
	
	pass

func _process(_delta):
	immediate_mesh.clear_surfaces()
	#draw_chunk_borders()
	if not lines_to_draw.is_empty():
		draw_lines()
	canvas_item.queue_redraw()

var move_chunkborders_with_cam: bool = true
func _physics_process(_delta):
	if move_chunkborders_with_cam:
		chunkborders_mesh_instance.position = (
			floor((cam_node.position + 
			Vector3(float(chunk_length)/2.0, float(chunk_length)/2.0, float(chunk_length)/2.0)) / 
			float(chunk_length)) * float(chunk_length)
		)

func draw_chunk_borders():
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	#immediate_mesh.surface_set_color(Color(1, 0, 0))
	#immediate_mesh.surface_add_vertex(Vector3(-10, -10, -10))
	#immediate_mesh.surface_add_vertex(Vector3(10, 10, 10))
	immediate_mesh.surface_end()

# Assumes line format: [Vector3, Vector3, Color (optional)]
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
