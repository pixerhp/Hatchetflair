extends Node


const CHUNK_WIDTH: int = 16
const CHUNK_TILES_COUNT: int = CHUNK_WIDTH**3

enum LOD_TYPE {
	HIGH_QUALITY, # extra mesh details are generated based on substances + normals.
	MID_QUALITY, # mesh triangles use textures + render-materials, but don't generate finer details.
	LOW_QUALITY, # mesh triangles are textured and all use the same (a basic) render-material,
	GEO_LOD_1, # all terrain tiles are meshed as one mesh of simple marched cubes, based on occs. (no collision.)
	GEO_LOD_2, # same as before, but the marched cubes geometry is simplified to 8^3 rather than 16^3.
	GEO_LOD_4, # prior, but simplified to 4^3 (the size of a terrain-piece size.)
	GEO_LOD_8, # prior, but simplified to 2^4.
	GEO_LOD_16, # the entire chunk is represented as a single simple marched cubes node beside neighboring chunks'.
}
enum TILE_SHAPE {
	BLANK, 
	TESS_CUBE, #!!! NOT YET IMPLIMENTED
	TESS_OCTREE, #!!! NOT YET IMPLIMENTED
	TESS_RHOMBDO, #!!! NOT YET IMPLIMENTED
	MARCHED_SIMPLE, #!!! NOT YET IMPLIMENTED
	MARCHED_SMOOTH, #!!! NOT YET IMPLIMENTED
	CLIFF, # aka terraced? #!!! NOT YET IMPLIMENTED
}
enum TILE_OCC {
	EMPTY = 0, # contains no solid terrain (only atmosphere/gas/liquid/etc.)
	SEMI = 1, # "semi-empty" (half-tile slabs, partially encroaching neighboring solids, etc.)
	OCCUPIED = 2, # is the center of / is a space that has data for solid terrain
	ENGULFED = 3, # completely engulfed by surrounding solid terrain despite not itself being distinct solid terrain.
		# (For example, if a tile is surrounded on all sides by rhombdo tiles.)
}
enum TILE_OPAC { # note: occupiedness should also be considered for some related applications (particularly semi.)
	OPAQUE = 0, # the material is fully opaque.
	SCISSOR = 1, # the material allows some seeing-through via alpha-scissoring or similar.
	TRANSLUCENT = 2, # the material allows you to see through it but not fully transparently, such as stained glass.
	TRANSPARENT = 3, # the material is fully transparent.
}

class Chunk:
	var ccoords: Vector3i = Vector3i(0,0,0)
		# if a mobile/dynamic chunk, then this could get reused for which one this chunk is relative to a group.
	var tp_is_atm_bits: int = 0b0000000000000000 
		# Unloaded TPs can stay unloaded if it's known that they're just atmosphere.
	var tp_is_loaded_bits: int = 0b0000000000000000 
		# Whether each terrain piece has its data loaded in ram.
	var is_determinable_info_up_to_date: bool = false
	var terrain_pieces: Array[TerrainPiece] = []
	# var terrain_objects
		# liquid pools in particular, but potentially also things like grounded/lodged rocks, gems, etc.
		# instead of being separate node-tree objects, until dislodging- 
			# they can be rendered as part of the whole chunks' mesh?
		# regarding liquid pools, they should have a function to check- 
			# whether and how they are still contained, for pouring.
	# static structures stuff? (walls, floors, boards, windows, vents, etc.)
		# notably, structures fall along a finer grid (quarter-metrins?),
		# and aren't placed a way like where there's one per every cube unit of 
		# something like how terrain with tiles is.
	# Mesh/collision generation related:
	var lod_type: int = LOD_TYPE.MID_QUALITY
	
	
	
	# A chunk's terrain is broken up into 4^3 pieces, 
	# so that most of the unseen/unrelavent terrain can remain unloaded.
	class TerrainPiece:
		# Unique information:
		var tiles_shapes: PackedByteArray = [] # terrain shape type (marched, tess' cubes, etc.)
		var tiles_shapedatas: Array = [] # for storing shape-dependant additional data (slope, octree state, etc.) 
		var tiles_subs: PackedInt32Array = [] # terrain substances (smooth werium metal, conifer wood, etc.)
		var tiles_attachdatas: Array = [] # plants growing on terrain, paint and decals plastered on it, etc.
		# Determinable information, chached for quick access:
		var tiles_occs: PackedByteArray = [] # terrain occupiednesses
		var tiles_opacs: PackedByteArray = [] # terrain opacities
		
		
		pass
	
	
	
	
	func _init(in_ccoords: Vector3i):
		terrain_pieces.resize(4**3)
		ccoords = in_ccoords
		return
