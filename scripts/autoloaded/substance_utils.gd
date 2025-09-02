extends Node

var subst_rend_assets_location: String = "res://assets/substance_rendering/"
var albedos_folder_name: String = "albedos/"
var normals_folder_name: String = "normals/"
var specials_folder_name: String = "specials/"


var albedos_texarray: Texture2DArray = Texture2DArray.new()
var normals_texarray: Texture2DArray = Texture2DArray.new()
var specials_texarray: Texture2DArray = Texture2DArray.new()

var albedos_name_to_i: Dictionary[String,int] = {}
var normals_name_to_i: Dictionary[String,int] = {}
var specials_name_to_i: Dictionary[String,int] = {}

func _ready():
	initialize_texture_arrays()
	
	#print(albedos_texarray)
	#print(normals_texarray)
	#print(specials_texarray)
	#print()
	#print(albedos_name_to_i)
	#print(normals_name_to_i)
	#print(specials_name_to_i)


func initialize_texture_arrays():
	var albedos_array: Array[Image] = [load("res://unknown.png").get_image()]
	var normals_array: Array[Image] = [load("res://unknown.png").get_image()]
	var specials_array: Array[Image] = [load("res://unknown.png").get_image()]
	var dir: DirAccess
	
	# Albedos
	dir = DirAccess.open(subst_rend_assets_location + albedos_folder_name)
	if not dir:
		push_error("Failed to access substance rendering assets albedo textures folder.")
	for file: String in dir.get_files():
		if not file.get_extension() == "png": continue
		albedos_array.append(load(subst_rend_assets_location + albedos_folder_name + file).get_image())
		if albedos_array[albedos_array.size()-1] == null: albedos_array.pop_back()
		else: albedos_name_to_i[file.get_basename()] = albedos_array.size()-1
	albedos_texarray.create_from_images(albedos_array)
	
	# Normals
	dir = DirAccess.open(subst_rend_assets_location + normals_folder_name)
	if not dir:
		push_error("Failed to access substance rendering assets normal map textures folder.")
	for file: String in dir.get_files():
		if not file.get_extension() == "png": continue
		normals_array.append(load(subst_rend_assets_location + normals_folder_name + file).get_image())
		if normals_array[normals_array.size()-1] == null: normals_array.pop_back()
		else: normals_name_to_i[file.get_basename()] = normals_array.size()-1
	albedos_texarray.create_from_images(normals_array)
	
	# Specials
	dir = DirAccess.open(subst_rend_assets_location + specials_folder_name)
	if not dir:
		push_error("Failed to access substance rendering assets specials textures folder.")
	for file: String in dir.get_files():
		if not file.get_extension() == "png": continue
		specials_array.append(load(subst_rend_assets_location + specials_folder_name + file).get_image())
		if specials_array[specials_array.size()-1] == null: specials_array.pop_back()
		else: specials_name_to_i[file.get_basename()] = specials_array.size()-1
	albedos_texarray.create_from_images(specials_array)
