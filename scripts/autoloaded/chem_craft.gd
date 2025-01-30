extends Node


enum SUBS_CAT { # "substance category"
	PURE_ELEMENT, # only contains 1 element, such as pure ferrium, pure diamond and graphite, etc.
	METAL, # includes pure metals, somewhat-refined metals, metal alloys, etc.
	NOBLE_GAS, # icluded noble gas mixtures.
	WOOD,
}

class Substance:
	var names: PackedStringArray = [] # A substance's "main"/"default" name is the one listed first.
	var density: float = 1 # density in [standardized weight unit] per cubic metrin.
	var categories: PackedInt32Array = []
	# !!! add rendering and mesh related info / references to info
	
	func _init(in_names: PackedStringArray, in_density: float):
		names.clear()
		names.append_array(in_names)
		density = in_density

var substances: Array[Substance] = [
	Substance.new(
		["ferrium", "ferry", "iron"],
		1, # !!! change later
	),
]



# !!! define substances' relation with other substances, their melting/boiling/decomposition/etc temperatures, etc.







func _ready():
	pass

