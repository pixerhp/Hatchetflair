# A script that defines substances, their relations to other elements and reactions to temperature,
# chemistry, crafting of things into other things, composite objects and what substances they're made of, etc.
extends Node


class Substance:
	var names: PackedStringArray = [] # A substance's "main"/"default" name is the one listed first.
	var tags: PackedInt32Array = []
	var density: float = 1 # density in [standardized weight unit] per cubic metrin.
	# !!! add rendering and mesh related info / references to info
	
	func _init(
		in_names: PackedStringArray, 
		in_tags: PackedInt32Array,
		in_density: float,
	):
		names.clear()
		names.append_array(in_names)
		tags.clear()
		tags.append_array(in_tags)
		density = in_density

# note: if a tag like "organic" exists, then there does not need to be an "inorganic" tag,
# as simply not having the "organic" tag would imply being inorganic.
enum SUBS_TAG { # "substance tag"
	PURE_ELEMENT, # only contains 1 element, such as pure ferrium, pure diamond mixed with graphite, etc.
	PURE_SUBSTANCE, # pure water, pure sulfuric acid, pure diamond with no graphite or vice versa, etc.
	METAL, # includes pure metals, somewhat-refined metals, metal alloys, etc.
	NOBLE_GAS, # noble gases and noble gas mixtures.
	PROCESSED_WOOD, # debarked and sawed wood, like planks and boards.
	DYE, 
}

var substance_name_to_i: Dictionary = {}

func get_substance(subs_main_name: String) -> Substance:
	return substances[substance_name_to_i[subs_main_name]]

var substances: Array[Substance] = [
	Substance.new(
		["air"],
		[],
		1.0, # !!! set later, this value is temporary due to not having decided on a standard mass unit yet.
	),
	Substance.new(
		["ferrium", "ferry", "iron"],
		[SUBS_TAG.PURE_ELEMENT, SUBS_TAG.METAL],
		1.0, # !!! set later, this value is temporary due to not having decided on a standard mass unit yet.
	),
]

# These define FUNCTIONAL states of matter rather than describing lore/worldbuilding.
# Ex. What may in-universe be considered a "plasma" may functionally still be treated as a gas.
enum STATE_OF_MATTER {
	SOLID,
	LIQUID,
	GAS, # would also include plasmas and supercritical fluids.
	# SUPERFLUID ? has 0 viscosity, can climb walls of container.
	# BE_CONDENSATE ?
}



# !!! define substances' relation with other substances, their melting/boiling/decomposition/etc temperatures, etc.




func _ready():
	# Prepare the substance_name_to_i dictionary, which may be used by various code/threads.
	substance_name_to_i.clear()
	for i in substances.size():
		substance_name_to_i[substances[i].names[0]] = i
