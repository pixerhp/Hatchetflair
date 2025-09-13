extends Node

class PATHS:
	const subst_assets_path: String = "res://assets/substance_assets/"
	const albedos_textures: String = subst_assets_path + "albedos/"
	const normals_textures: String = subst_assets_path + "normals/"
	const specials_textures: String = subst_assets_path + "specials/"
	const substs_data: String = subst_assets_path + "substances.csv"

class Subst:
	var name: String = ""
	# var value: float ?
	var default_albedo_tex: int = -1
	var default_vert_color: Color = Color.WHITE
	#var alt_albedo_tex: int = -1
	#var alt_vert_color: Color = Color.WHITE
	var default_normal_tex: int = -1
	#var alt_normal_tex: int = -1
	var default_special_tex: int = -1
	#var alt_special_tex: int = -1

var SUBSTANCES: Array[Subst] = []
var subst_name_to_i: Dictionary[String,Subst] = {}

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
			img.convert(Image.FORMAT_RGBA8)
			if img.get_size() != Vector2i(256, 256):
				push_warning("Texture: \"", filename, "\" is not 256x256, thus will be resized before use.")
				img.resize(256, 256)
			temp_imagearray.append(img)
			[albedos_name_to_i,normals_name_to_i,specials_name_to_i][i][filename.get_basename()] = (
				temp_imagearray.size() - 1)
		[albedos_texarray,normals_texarray,specials_texarray][i].create_from_images(temp_imagearray.duplicate())

func initialize_substances():
	pass
