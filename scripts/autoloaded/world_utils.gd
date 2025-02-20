extends Node


const CHUNK_WIDTH: int = 16
const CHUNK_TILES_COUNT: int = CHUNK_WIDTH**3

# Current loaded world's seeds and generational/spawning settings:
var world_seed: int = 0
#var ocean_height: int = 0

enum CHUNK_LOD {
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
	TERRACE, # aka terraced? #!!! NOT YET IMPLIMENTED
	# POWDER? #!!! NOT YET IMPLIMENTED
}

# Tile occupiedness (regarding solid terrain, not fluid occupation.)
enum TILE_OCC { # used to determine whether/how fluids can reside within the tile and for placement.
	EMPTY = 0, # contains no solid terrain (only atmosphere/gas/liquid/fluids/etc.)
	PARTIAL = 1, # "semi-empty" (half-tile slabs, partially encroaching neighboring solids, etc.)
	ENGULFED = 2, # completely engulfed by surrounding solid terrain, despite itself being empty terrain.
		# (For example, if a tile is surrounded on all sides by rhombdo tiles.)
	OCCUPIED = 3, # is the center of / is a space that has data for solid terrain
}
# The directions that fluids can/can't flow in/across a tile.
enum TILE_FLOW {
	NONE = 0, # fluids may not flow through the tile.
	LATERAL = 1, # fluids may only flow laterally (z1/z2) within/across the tile.
	VERTICAL = 2, # fluids may only flow vertically (h) within/across the tile.
	OMNI = 3, # fluids may flow in any direction (h/z1/z2) within/across the tile.
}
# Tile stability (the situation around whether tiles may structurally collapse.)
enum TILE_STAB {
	FIXED = 0, # Inherently stable terrain that cannot collapse.
	STABLE = 1, # Collapsable terrain that is currently in a stable situation.
		# Ex. Dry powder sitting on top of bedrock, it is well supported.
	SENSITIVE = 2, # Is primed to collapse upon direct interaction or things like nearby explosions.
		# Ex. Sticky/wet powder, precarious rocks or a very crumbly substance overhanging atmosphere.
	UNSTABLE = 3, # Imminent for immediate collapse without provocation.
		# Ex. Dry powder overhanging/above atmosphere, it should collapse immediately.
}
# Whether a tile's transparency should be rendered, for mesh generation.
	# Think of how if you have a thick wall of leaf blocks in minecraft, they're rendered as opaque a few layers in.
enum TILE_REND_OPAQ {
	DO_TRANSPARENCY = 0,
	FORCE_OPAQUE = 1,
}

class Chunk:
	var associated_nodes_refs: Array[Object] = []
		# Stores references to all of this chunk's associated scene tree nodes, for quick access to them.
	var ccoords: Vector3i = Vector3i(0,0,0)
		# if a mobile/dynamic chunk, then this could get reused for which one this chunk is relative to a group.
	
	# NOTE: terrain piece bitstuff works like this:
		# of the 64 (4*4*4) terrain pieces, in hzz format, the first tp is the (0,0,0) one,
		# the second tp is the (0,0,1) one, etc up until the fourth tp, (0,0,3).
		# then the z1 increments and z2 resets back to 0, so the fifth tp is the (0,1,0) one.
		# the patten continues until both z1 and z2 are 3, and then h increments by 1 and z1 & z2 are set to 0.
		# the last tp is (3,3,3), which is the 64th tp.
		#
		# the 64 bits are stored using an 8 element long packed byte array, 
		# where the first bit in the the first byte corresponds to the first tp.
	var tp_is_atm_bitstates: PackedByteArray = []
		# Unloaded TPs can stay unloaded if it's known that they're just atmosphere.
	var tp_is_loaded_bitstates: PackedByteArray = []
		# Whether each terrain piece has its data loaded in ram.
	
	var determinables_uptodate: Array[PackedByteArray] = [[], [], [],]
	
	var terrain_pieces: Array[TerrainPiece] = []
	# var terrain_objects
		# liquid pools in particular, but potentially also things like grounded/lodged rocks, gems, etc.
		# instead of being separate node-tree objects, until dislodging- 
			# they can be rendered as part of the whole chunks' mesh?
		# regarding liquid pools, they should have a function to check- 
			# whether and how they are still contained, for pouring (whether around here or in CM.)
	# static structures stuff? (walls, floors, boards, windows, vents, stairs, etc etc.)
		# notably, structures fall along a finer grid (probably quarter-metrins aka 1/256 of a chunk width,)
		# and aren't placed in a way like where there's one per every cube unit of 
		# something like how terrain is with tiles, and can take up various shapes/sizes.
	# Mesh/collision generation related:
	var lod_type: int = CHUNK_LOD.MID_QUALITY
	
	var biome: int = 0 # !!! not yet used, will probably store a biome enum value.
	
	func _init(in_ccoords: Vector3i):
		ccoords = in_ccoords
		tp_is_atm_bitstates.resize(8); tp_is_atm_bitstates.fill(0b11111111)
		tp_is_loaded_bitstates.resize(8); tp_is_loaded_bitstates.fill(0b11111111)
		reset_terrain_pieces()
		return
	
	# A chunk's terrain is broken up into 4^3 pieces, 
		# so that most of the unseen/unrelavent terrain can remain unloaded.
	class TerrainPiece:
		# Unique information:
		var tiles_shapes: PackedByteArray = [] # terrain shape type (marched, tess' cubes, etc.)
		#var tiles_shapedatas: Array = [] # for storing shape-dependant additional data (slope, octree state, etc.) 
		var tiles_subs: PackedInt32Array = [] # terrain substances (smooth werium metal, conifer wood, etc.)
		#var tiles_attachdatas: Array = [] # for paint and decals, plants growing on the terrain, etc.
		
		# Determinable information, chached for quick access:
		var tiles_determinables: PackedByteArray = []
		
		func clear_all_data():
			tiles_shapes.clear()
			#tiles_shapedatas.clear()
			tiles_subs.clear()
			#tiles_attachdatas.clear()
			tiles_occs.clear()
			tiles_opacs.clear()
			return
	
	func reset_terrain_pieces():
		terrain_pieces.clear()
		terrain_pieces.resize(4**3)
		terrain_pieces.fill(TerrainPiece.new())
	
	
	# !!! update bitstuff to use packed byte array
	# (Can be done here as chunk terrain generation is not dependant on surrounding chunks' data.)
	func generate_natural_terrain(
		tps_to_generate: PackedByteArray = [255, 255, 255, 255, 255, 255, 255, 255], # 64 1's in binary 
		also_clear_unrelated_tp_data: bool = false, 
		seed: int = WorldUtils.world_seed,
	) -> Error:
		if terrain_pieces.size() != (4**3):
			push_error("Chunk has ", terrain_pieces.size(), " terrain pieces (instead of 64).")
			reset_terrain_pieces()
		
		for tp_i in (4**3):
			if tps_to_generate[tp_i/8] & (0b1 << posmod(tp_i, 8)):
				terrain_pieces[tp_i].clear_all_data()
				
				# !!! write terrain generation testing code here
				
			elif also_clear_unrelated_tp_data:
				terrain_pieces[tp_i].clear_all_data()
		
		return OK
