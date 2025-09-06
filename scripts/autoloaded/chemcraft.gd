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
	# intialize crafting? determine substance values?

func initialize_substance_textures():
	pass

func initialize_substances():
	pass
