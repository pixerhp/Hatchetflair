extends Node

class PATHS:
	const subst_assets_path: String = "res://assets/substance_assets/"
	const albedos_textures: String = subst_assets_path + "albedos/"
	const normals_textures: String = subst_assets_path + "normals/"
	const specials_textures: String = subst_assets_path + "specials/"
	const substs_data: String = subst_assets_path + "substances.csv.txt"

class Subst:
	var name: String = ""
	# var value: float ?
	var albedo_ind: int = -1
	var vert_color: Color = Color.WHITE
	#var alt_albedo_tex: int = -1
	#var alt_vert_color: Color = Color.WHITE
	var normal_ind: int = -1
	#var alt_normal_tex: int = -1
	var special_ind: int = -1
	#var alt_special_tex: int = -1

# !!! can later replace dicts with simple name array, 
# given that each name corresponds to a single index from 0 to size - 1?

var SUBSTANCES: Array[Subst] = []
var subst_name_to_i: Dictionary[String,int] = {} 

var albedos_texarray: Texture2DArray = Texture2DArray.new()
var normals_texarray: Texture2DArray = Texture2DArray.new()
var specials_texarray: Texture2DArray = Texture2DArray.new()

var albedos_name_to_i: Dictionary[String,int] = {}
var normals_name_to_i: Dictionary[String,int] = {}
var specials_name_to_i: Dictionary[String,int] = {}

func _ready():
	initialize_substance_textures()
	initialize_substances()
	# !!! intialize crafting? determine substance values?

func initialize_substance_textures():
	var temp_imagearray: Array[Image] = []
	var textures_folder_path: String = ""
	var dir: DirAccess
	for i in range(3):
		temp_imagearray.clear()
		textures_folder_path = [PATHS.albedos_textures, PATHS.normals_textures, PATHS.specials_textures][i]
		dir = DirAccess.open(textures_folder_path)
		if not DirAccess.get_open_error() == OK:
			push_error("Failed to access a substance rendering texture assets folder.")
		for filename: String in dir.get_files():
			if not filename.get_extension() == "png": continue
			var img: Image = load(textures_folder_path + filename).get_image()
			if img == null: continue
			img.convert(Image.FORMAT_RGB8)
			if img.get_size() != Vector2i(256, 256):
				push_warning("Texture: \"", filename, "\" is not 256x256, thus will be resized before use.")
				img.resize(256, 256)
			temp_imagearray.append(img)
			[albedos_name_to_i,normals_name_to_i,specials_name_to_i][i][filename.get_basename()] = (
				temp_imagearray.size() - 1)
		[albedos_texarray,normals_texarray,specials_texarray][i].create_from_images(temp_imagearray.duplicate())

func initialize_substances():
	var file: FileAccess = FileAccess.open(PATHS.substs_data, FileAccess.READ)
	var csv_data: PackedStringArray = []
	while file.get_position() < file.get_length():
		csv_data = file.get_csv_line(",")
		if csv_data.size() < 2: 
			continue # (skip over empty/placeholder data.)
		if csv_data.size() != 7:
			push_warning("Bad substances csv data: ", csv_data)
			continue
		var new_subst: Subst = Subst.new()
		new_subst.name = csv_data[0]
		new_subst.albedo_ind = albedos_name_to_i.get(csv_data[1], -2)
		new_subst.vert_color = Color(float(csv_data[2]), float(csv_data[3]), float(csv_data[4]))
		new_subst.normal_ind = normals_name_to_i.get(csv_data[5], -2)
		new_subst.special_ind = specials_name_to_i.get(csv_data[6], -2)
		subst_name_to_i[new_subst.name] = SUBSTANCES.size()
		SUBSTANCES.append(new_subst)
