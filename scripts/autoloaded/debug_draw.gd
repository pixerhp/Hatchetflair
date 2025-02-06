# !!! this whole script is a mess.

# The original debug_draw script by Zylann: 
	# https://github.com/Zylann/godot_debug_draw
# This script is a personal edit of someone's rework which updated Zylann's to Godot 4: 
	# https://codefile.io/f/7GIUyZdW5g3xqKzSzMQw

## @brief Single-file autoload for debug drawing and text printing.
## Draw and print on-screen from anywhere with a single line of code.

extends CanvasLayer

## @brief How many frames HUD text lines remain shown after being invoked.
const TEXT_LINGER_FRAMES = 0
## @brief How many frames lines remain shown after being drawn.
const LINES_LINGER_FRAMES = 0
## @brief Color of the text drawn as HUD
const TEXT_COLOR = Color(1,1,1)
## @brief Background color of the text drawn as HUD
const TEXT_BG_COLOR = Color(0, 0, 0, 0.75)

# 2D
var dd_canvas_item: CanvasItem = null
var _texts: Array[String] = []
var _font: Font = ThemeDB.fallback_font

# 3D
var _boxes: Array = []
var _box_pool: Array = []
var _box_mesh: Mesh = null
var _line_material_pool: Array = []

var _lines: Array = []
var _line_immediate_geometry: ImmediateMesh = ImmediateMesh.new()

var _mesh_instance: MeshInstance3D = MeshInstance3D.new()


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# !!! figure out what this does and see if it should be reduced:
	layer = 100
	
	_mesh_instance.mesh = _line_immediate_geometry
	_mesh_instance.material_override = _get_line_material()
	
	add_child(_mesh_instance)
	
	refresh_debug_chunk_borders()


## @brief Draws the unshaded outline of a 3D cube.
## @param position: world-space position of the center of the cube
## @param size: size of the cube in world units
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_cube(position: Vector3, size: float, color: Color = Color.WHITE, linger := 0):
	draw_box(position, Vector3(size, size, size), color, linger)





var chunk_borders_lines_vects: PackedVector3Array = []
var chunk_borders_lines_colors: PackedColorArray = []

func refresh_debug_chunk_borders():
	chunk_borders_lines_vects.clear()
	chunk_borders_lines_colors.clear()
	_add_chunk_border_shell(0, [Color(0.25, 0.25, 0), Color(0, 0.25, 0.25), Color(0.25, 0, 0.25)])
	_add_chunk_border_shell(1, [Color.RED, Color.RED, Color.RED])
	_add_chunk_border_shell(2, [Color(0.05, 0, 0), Color(0.05, 0, 0), Color(0.05, 0, 0)])
	return

func _add_chunk_border_shell(shell_num: int, hzz_colors: PackedColorArray):
	if shell_num == 0:
		_add_chunk_border_single(Vector3(0,0,0), 0b111111111111, PackedColorArray([Color.CRIMSON, Color.CRIMSON, Color.CRIMSON]))
		
		_add_chunk_border_single(Vector3(-0.00390625,-0.00390625,-0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3(-0.00390625,-0.00390625, 0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3(-0.00390625, 0.00390625,-0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3(-0.00390625, 0.00390625, 0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3( 0.00390625,-0.00390625,-0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3( 0.00390625,-0.00390625, 0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3( 0.00390625, 0.00390625,-0.00390625), 0b111111111111, hzz_colors)
		_add_chunk_border_single(Vector3( 0.00390625, 0.00390625, 0.00390625), 0b111111111111, hzz_colors)
		
		return
	
	var bitmask: int = 0b111111111111
	for h in range(-1 * shell_num, shell_num + 1):
		for z1 in range(-1 * shell_num, shell_num + 1):
			for z2 in range(-1 * shell_num, shell_num + 1):
				bitmask = 0b111111111111
				
				if h == (-1 * shell_num):
					bitmask = bitmask & 0b000011111111
				if h == (shell_num):
					bitmask = bitmask & 0b111111110000
				if z1 == (-1 * shell_num):
					bitmask = bitmask & 0b011100110111
				if z1 == (shell_num):
					bitmask = bitmask & 0b111011001110
				if z2 == (-1 * shell_num):
					bitmask = bitmask & 0b101101011011
				if z2 == (shell_num):
					bitmask = bitmask & 0b110110101101
				
				if (bitmask == 0b111111111111) or (bitmask == 0b000000000000):
					continue
				else:
					_add_chunk_border_single(Globals.swap_zyx_hzz_f(Vector3(h,z1,z2)), bitmask, hzz_colors)
	
	
	return

func _add_chunk_border_single(relative_ccoords: Vector3, bitmask: int, hzz_colors: PackedColorArray):
	var vertex_multiplier: Vector3 = Vector3(ChunkUtils.CHUNK_WIDTH, ChunkUtils.CHUNK_WIDTH, ChunkUtils.CHUNK_WIDTH)
	for n in range(0,12):
		if bitmask & (0b000000000001 << n):
			match n:
				0:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[2])
				1:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[1])
				2:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[1])
				3:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[2])
				4:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[0])
				5:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[0])
				6:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[0])
				7:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3(-0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[0])
				8:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[2])
				9:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[1])
				10:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3( 0.5,-0.5, 0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[1])
				11:
					chunk_borders_lines_vects.append_array([
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5,-0.5)) + relative_ccoords) * vertex_multiplier, 
						(Globals.swap_zyx_hzz_f(Vector3( 0.5, 0.5, 0.5)) + relative_ccoords) * vertex_multiplier
					])
					chunk_borders_lines_colors.append(hzz_colors[2])
				_:
					push_error("??? this should be impossible.")
	return


var player_position_for_chunk_borders: Vector3 = Vector3(0,0,0)
func _process_chunk_borders():
	if chunk_borders_lines_vects.size() == 0:
		return
	
	var ccoord_offset: Vector3 = floor((player_position_for_chunk_borders + Vector3(8,8,8)) / ChunkUtils.CHUNK_WIDTH)
	var repositioned_vects: PackedVector3Array = []
	repositioned_vects.resize(chunk_borders_lines_vects.size())
	for i in chunk_borders_lines_vects.size():
		repositioned_vects[i] = chunk_borders_lines_vects[i] + (16*ccoord_offset)
	
	_line_immediate_geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in chunk_borders_lines_colors.size():
		_line_immediate_geometry.surface_set_color(chunk_borders_lines_colors[i])
		_line_immediate_geometry.surface_add_vertex(repositioned_vects[i*2])
		_line_immediate_geometry.surface_add_vertex(repositioned_vects[(i*2)+1])
	
	_line_immediate_geometry.surface_end()
	return


## @brief Draws the unshaded outline of a 3D box.
## @param position: world-space position of the center of the box
## @param size: size of the box in world units
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_box(position: Vector3, size: Vector3, color: Color = Color.WHITE, linger_frames = 0):
	var mi := _get_box()
	var mat := _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = position
	mi.scale = size
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES + linger_frames
	})


## @brief Draws the unshaded outline of a 3D transformed cube.
## @param trans: transform of the cube. The basis defines its size.
## @param color
func draw_transformed_cube(trans: Transform3D, color: Color = Color.WHITE):
	var mi := _get_box()
	var mat := _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.transform = Transform3D(trans.basis, trans.origin - trans.basis * Vector3(0.5,0.5,0.5))
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES
	})


## @brief Draws the basis of the given transform using 3 lines
##        of color red for X, green for Y, and blue for Z.
## @param transform
## @param scale: extra scale applied on top of the transform
func draw_axes(transform: Transform3D, scale: float = 1.0, is_hzz: bool = false):
	if is_hzz:
		draw_ray_3d(transform.origin, transform.basis.y, scale, Color(1,1,0)) # h
		draw_ray_3d(transform.origin, -1 * transform.basis.z, scale, Color(1,0,1)) # z1
		draw_ray_3d(transform.origin, transform.basis.x, scale, Color(0,1,1)) # z2
	else:
		draw_ray_3d(transform.origin, transform.basis.x, scale, Color(1,0,0)) # x
		draw_ray_3d(transform.origin, transform.basis.y, scale, Color(0,1,0)) # y
		draw_ray_3d(transform.origin, transform.basis.z, scale, Color(0,0,1)) # z


## @brief Draws the unshaded outline of a 3D box.
## @param aabb: world-space box to draw as an AABB
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_box_aabb(aabb: AABB, color = Color.WHITE, linger_frames = 0):
	var mi := _get_box()
	var mat := _get_line_material()
	mi.translation = aabb.position
	mi.scale = aabb.size
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES + linger_frames
	})
	mat.albedo_color = color
	mi.material_override = mat



func draw_line_3d(from: Vector3, to: Vector3, color: Color):
	_lines.append([from, to, color])

func draw_ray_3d(origin: Vector3, direction: Vector3, length: float, color : Color):
	draw_line_3d(origin, origin + (direction.normalized() * length), color)

func add_text(str: String):
	_texts.append(str)


func _get_box() -> MeshInstance3D:
	var mi : MeshInstance3D
	if len(_box_pool) == 0:
		mi = MeshInstance3D.new()
		if _box_mesh == null:
			_box_mesh = _create_wirecube_mesh(Color.WHITE)
		mi.mesh = _box_mesh
		add_child(mi)
	else:
		mi = _box_pool[-1]
		_box_pool.pop_back()
	return mi


func _recycle_box(mi: MeshInstance3D):
	mi.hide()
	_box_pool.append(mi)


func _get_line_material() -> StandardMaterial3D:
	var mat : StandardMaterial3D
	if len(_line_material_pool) == 0:
		mat = StandardMaterial3D.new()
		mat.flags_unshaded = true
		mat.vertex_color_use_as_albedo = true
	else:
		mat = _line_material_pool[-1]
		_line_material_pool.pop_back()
	return mat


func _recycle_line_material(mat: StandardMaterial3D):
	_line_material_pool.append(mat)


func _process(_delta):
	_process_boxes()
	_process_lines()
	if Globals.draw_debug_chunk_borders:
		_process_chunk_borders()
	_process_canvas()


func _process_3d_boxes_delayed_free(items: Array):
	var i := 0
	while i < len(items):
		var d = items[i]
		if d.frame <= Engine.get_frames_drawn():
			_recycle_line_material(d.node.material_override)
			d.node.queue_free()
			items[i] = items[len(items) - 1]
			items.pop_back()
		else:
			i += 1


func _process_boxes():
	_process_3d_boxes_delayed_free(_boxes)

	# Progressively delete boxes in pool
	if len(_box_pool) > 0:
		var last = _box_pool[-1]
		_box_pool.pop_back()
		last.queue_free()


func _process_lines():
	_line_immediate_geometry.clear_surfaces()
	
	if _lines.size() == 0:
		return
	
	_line_immediate_geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for line in _lines:
		_line_immediate_geometry.surface_set_color(line[2])
		_line_immediate_geometry.surface_add_vertex(line[0])
		_line_immediate_geometry.surface_add_vertex(line[1])
	
	_line_immediate_geometry.surface_end()
	_lines.clear()
	return


func _process_canvas():
	# Update the canvas.
	if dd_canvas_item == null:
		dd_canvas_item = Node2D.new()
		dd_canvas_item.position = Vector2(8, 8)
		dd_canvas_item.connect("draw", _on_CanvasItem_draw)
		add_child(dd_canvas_item)
	dd_canvas_item.queue_redraw()


func _on_CanvasItem_draw():
	var ci := dd_canvas_item
	
	var ascent := Vector2(0, _font.get_ascent())
	var pos := Vector2()
	var xpad := 2
	var ypad := 1
	var font_offset := ascent + Vector2(xpad, ypad)
	var line_height := _font.get_height() + 2 * ypad
	
	var string_size: Vector2 = Vector2(0, 0)
	for str in _texts:
		string_size = _font.get_string_size(str)
		ci.draw_rect(Rect2(pos, Vector2(string_size.x + xpad * 2, line_height)), TEXT_BG_COLOR)
		ci.draw_string(_font, pos + font_offset, str, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeDB.fallback_font_size, TEXT_COLOR)
		pos.y += line_height
	_texts.clear()


static func _create_wirecube_mesh(color: Color = Color.WHITE) -> ArrayMesh:
	var positions := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var colors := PackedColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices := PackedInt32Array([
		0, 1,
		1, 2,
		2, 3,
		3, 0,
		
		4, 5,
		5, 6,
		6, 7,
		7, 4,
		
		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh
