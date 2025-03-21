# A script that defines substances, their relations to other elements and reactions to temperature,
# chemistry, crafting of things into other things, composite objects and what substances they're made of, etc.

# HATCHETFLAIR STANDARD UNITS:
# length 
	# metrin (m) -- (equal to 1.5 imperial feet.)
# volume 
	# cubic metrin (m³)
	# (hf) liter (l) -- (defined as 1/100th of a cubic metrin, is equal to ~0.95569357 irl metric liters.)
	# (hf) gallon (gl) -- (defined as 4 (hf) liters, is equal to ~1.00987 USA liquid gallons.)
# mass
	# !!! ((hf) gram (g) ???; "pam"/"pram" (p)?) -- (equal to 1 irl metric kilogram.)
# time
	# second (s)
# energy
	# joule (j)
# power
	# watt (w)
# force
	# !!! newtons analog?

extends Node


const DYE_COLORS: Dictionary[String, Color] = {
	"pure black": Color.BLACK,
	"pure white": Color.WHITE,
	
	"pure red": Color.RED,
	"pure yellow": Color.YELLOW,
	"pure green": Color.GREEN,
	"pure cyan": Color.CYAN,
	"pure blue": Color.BLUE,
	"pure magen": Color.MAGENTA,
	
	"pure orange": Color(1, 0.5, 0),
	"pure shar": Color(0.5, 1, 0),
	"pure menth": Color(0, 1, 0.5),
	"pure azhur": Color(0, 0.5, 1),
	"pure violet": Color(0.5, 0, 1),
	"pure rose": Color(1.0, 0.0, 0.5),
	
	"pure indigo": Color(0.25, 0.0, 1.0),
	"digodium": Color(0.317, 0.0, 1.0),
	"pure crimson": Color(1.0, 0.0, 0.25),
}


# Substances have unique chemistry, crafting, thermal interactions (etc,) 
	# and point to a SubsProps for their properties.
# Things with independant crafting/chemistry/value/etc yet share physical properties (such as dyes,)
	# should all point to the same SubsProp.
class Substance:
	var names: PackedStringArray = [] # A substance's "main"/"default" name is the one listed first.
	var tags: PackedInt32Array = []
	var subsprop_i: int = -1
	# !!! add rendering and mesh related info / references to info
	# !!! mesh detailing style (referenced with index int?)
	
	func _init(
		in_names: PackedStringArray, 
		in_tags: PackedInt32Array,
		in_subsprop_i: int,
	):
		names.clear()
		names.append_array(in_names)
		tags.clear()
		tags.append_array(in_tags)
		subsprop_i = in_subsprop_i
	
	func get_properties() -> SubsProp:
		if subsprop_i == -1:
			push_error("This Substance has no associated SubsProp index.")
			return ChemCraft.bad_subsprop
		else:
			return ChemCraft.subsprops[subsprop_i]

# an anti-crash default substance that can be used wherever for if a non-existant substance is called for.
var bad_substance: Substance = Substance.new(["bad substance"], [], -1)

# Substance instances are separated from their properties so that multiple substances can share properties. 
# For example, the dyes have different crafting/chemistry/rendering, but can share physical properties.
class SubsProp:
	var name: String = "" 
		# For ease of linking substances to their properties regardless of subsprops list element order.
	
	# not state of matter dependant:
	var ion_emmission_color: Color 
	
	# solid
	var s_density: float = 1 # density in [standardized weight unit] per cubic metrin.
	var s_elec_resis: float = 1 # 0 is a valid input, representing electrical superconductors.
	var s_hardness: float = 1
	
	# liquid
	var l_density: float  = 1
	var l_elec_resis: float = 1 # 0 is a valid input, representing electrical superconductors.
	var l_viscosity: float = 1
	# cohesion & adhesion?
	
	# gas/vapor
	var g_density: float = 1
	var g_elec_resis: float = 1 # 0 is a valid input, representing electrical superconductors.
	
	# thermal conductivity/insulation?
	
	# !!! Add full initialization later.
	func _init(
		in_name: String,
	):
		name = in_name

# an anti-crash default subsprop that can be used wherever for if a non-existant subsprop is called for.
var bad_subsprop: SubsProp = SubsProp.new("bad subsprop")

# Note: if a tag like "organic" exists, then there shouldn't be an "inorganic" tag,
# as a substance simply not having the "organic" tag would imply it being inorganic.
enum SUBS_TAG { # "substance tag"
	PURE_ELEMENT, # only contains 1 element, such as pure ferrium, pure diamond mixed with graphite, etc.
	PURE_SUBSTANCE, # pure water, pure sulfuric acid, pure diamond with no graphite or vice versa, etc.
	METAL, # includes pure metals, somewhat-refined metals, metal alloys, etc.
	NOBLE_GAS, # noble gases and noble gas mixtures.
	PROCESSED_WOOD, # debarked and sawed wood, like planks and boards.
	DYE, 
}

enum MESH_DETAILING_STYLE {
	NONE,
	BRICKS,
	SHALE,
}

# These define FUNCTIONAL states of matter rather than describing lore/worldbuilding.
# Ex. What may in-universe be considered a "plasma" may functionally still be treated as a gas.
enum STATE_OF_MATTER {
	SOLID,
	LIQUID,
	GAS, # would also include plasmas and supercritical fluids.
	# SUPERFLUID ? has 0 viscosity, can climb walls of container.
	# BE_CONDENSATE ?
}


var substances: Array[Substance] = []

var substance_name_to_i: Dictionary = {}
func get_substance(subs_main_name: String) -> Substance:
	return substances[substance_name_to_i[subs_main_name]]

var subsprops: Array[SubsProp] = []

var subsprop_name_to_i: Dictionary = {}
func get_subsprop(subsprop_name: String) -> SubsProp:
	return subsprops[subsprop_name_to_i[subsprop_name]]



enum REACTION_TYPE {
	# State of matter changes:
	MELT_FREEZE,
	BOIL_CONDENSATE,
	SUBLIMATE_DEPOSIT,
	# Chemistry:
	DECOMPOSITION, # beyond a temperature, breaks down into (usually several) different substances.
	PYROLYSIS, # like decomposition, but requires the absense of one or more (usually fluid) substances.
	COMBINATION, # where two or more substances combine together into one or more substances.
	
}

# !!! What is chemistry actually functionally?
	# one or more mixed/together substances, 
	# in the absense of 0 or more substances, 
	# beyond or in-relation to a certain temperature(s),
	# result in one or more substances,
	# producing/removing some amount of heat.

class ChemReaction :
	var required_subs: PackedInt32Array = []
		# the input substances of the reaction.
	# !!! ratio used of required substances?
	var disrequired_subs: PackedInt32Array = [] 
		# substances which prevent the reaction, think of pyrolysis requiring a lack of oxygen.
	var activation_temp: float = -1 # (using the standard absolute scale temperature unit, probably kelvin.)
		# the minimum temperature required for the reaction to occur.
	# !!! reaction speed formula in relation to temperature?
	# !!! catalyst substances and how much / in what way they change reaction speed / temperature?
		# (this can include inhibitors which slow down a reaction and/or make the activation temp higher.)

var chem_reactions: Array[ChemReaction] = []
var chem_reaction_name_to_i: Dictionary = {}
func get_chem_reaction(chem_reaction_name: String) -> ChemReaction:
	return chem_reactions[chem_reaction_name_to_i[chem_reaction_name]]

# !!! define substances' relation with other substances, their melting/boiling/decomposition/etc temperatures, etc.


func _ready():
	# Note: the order of these functions matters due to depending on eachother.
	initialize_subsprops_list()
	prepare_subsprop_name_to_i_dict()
	initialize_substance_list()
	prepare_substance_name_to_i_dict()
	# !!! (initalizing chemistry/crafting related data)
	return

func initialize_subsprops_list() -> void:
	subsprops.clear()
	subsprops = [
		SubsProp.new(
			"air",
		),
		SubsProp.new(
			"ferrium",
		),
		SubsProp.new(
			"dye",
		),
	]
	return

func prepare_subsprop_name_to_i_dict() -> void:
	subsprop_name_to_i.clear()
	for i in subsprops.size():
		subsprop_name_to_i[subsprops[i].name] = i
	return

func initialize_substance_list() -> void:
	substances.clear()
	substances = [
		Substance.new(
			["air"],
			[],
			subsprop_name_to_i["air"],
		),
		Substance.new(
			["ferrium", "ferry", "iron"],
			[SUBS_TAG.PURE_ELEMENT, SUBS_TAG.METAL],
			subsprop_name_to_i["ferrium"],
		),
		Substance.new(
			["black dye"],
			[SUBS_TAG.DYE],
			subsprop_name_to_i["dye"],
		),
	]
	return

func prepare_substance_name_to_i_dict() -> void:
	substance_name_to_i.clear()
	for i in substances.size():
		substance_name_to_i[substances[i].names[0]] = i
	return
