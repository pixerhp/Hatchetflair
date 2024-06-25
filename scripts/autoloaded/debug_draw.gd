# Original code by Zylann: https://github.com/Zylann/godot_debug_draw
# This script originates from an altered version: https://codefile.io/f/7GIUyZdW5g3xqKzSzMQw
# This instance of the script is modified/updated for personal use by Pixer H. Pinecone (+ other HF devs.)

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


## @brief Draws the unshaded outline of a 3D cube.
## @param position: world-space position of the center of the cube
## @param size: size of the cube in world units
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_cube(position: Vector3, size: float, color: Color = Color.WHITE, linger := 0):
	draw_box(position, Vector3(size, size, size), color, linger)

func draw_chunk_corner(position_xyz: Vector3, side_length: float, colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE], centered: bool = true):
	var lines_origin: Vector3 = position_xyz
	if centered:
		lines_origin -= (Vector3(side_length, side_length, side_length) / 2)
	
	draw_line_3d(lines_origin, lines_origin + Vector3(side_length, 0, 0), colors[0])
	draw_line_3d(lines_origin, lines_origin + Vector3(0, side_length, 0), colors[1])
	draw_line_3d(lines_origin, lines_origin + Vector3(0, 0, side_length), colors[2])


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
	if _lines.size() == 0:
		_line_immediate_geometry.clear_surfaces()
		return
	
	_line_immediate_geometry.clear_surfaces()
	_line_immediate_geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for line in _lines:
		_line_immediate_geometry.surface_set_color(line[2])
		_line_immediate_geometry.surface_add_vertex(line[0])
		_line_immediate_geometry.surface_add_vertex(line[1])
	
	_line_immediate_geometry.surface_end()
	_lines.clear()


func _process_canvas():
	# Update canvas
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
