extends Node


class Chunk:
	const tile_count: int = 16**3
	# static vs moving chunk? for example, terrain vs a floating boat structure or a rolling massive boulder.
		# if moving/mobile, then the ccoords could get reused for relativity with  bound neighboring moving chunks.
	var ccoords: Vector3i = Vector3i(0,0,0)
	var terrain_pieces: Array[TerrainPiece] = []
	var terrain_objects
	# static structures stuff? (walls, floors, boards, windows, vents, etc.)
		# notably, structures fall along a finer grid (quarter-metrins?),
		# and aren't placed a way like where there's one per every cube unit of 
		# something like how terrain with tiles is.
	
	# A chunk's terrain is broken up into 4^3 pieces, 
	# so that most of the unseen/unrelavent terrain can remain unloaded.
	class TerrainPiece:
		# Unique information:
		var is_loaded: bool = false
		var tiles_shapes: PackedByteArray = [] # terrain shape type (marched, tess' cubes, etc.)
		var tiles_shapedatas: Array = [] # for storing shape-dependant additional data (slope, octree state, etc.) 
		var tiles_subs: PackedInt32Array = [] # terrain substances (smooth werium metal, conifer wood, etc.)
		var tiles_attachdatas: Array = [] # plants growing on terrain, paint and decals plastered on it, etc.
		# Determinable information, chached for quick access:
		var tiles_occs: PackedByteArray = [] # terrain occupiednesses
		var tiles_opacs: PackedByteArray = [] # terrain opacities
		
		
		pass
	
	
	
	
	func _init():
		terrain_pieces.resize(4**3)
		return





enum TILE_SHAPE {
	BLANK, 
	TESS_CUBE, 
	TESS_OCTREE, 
	TESS_RHOMBDO, 
	MARCHED_SIMPLE, 
	MARCHED_SMOOTH,
	CLIFF,
}


enum TILE_OCC {
	EMPTY = 0, # contains no solid terrain (only atmosphere/gas/liquid/etc.)
	SEMI = 1, # "semi-empty" (half-tile slabs, partially encroaching neighboring solids, etc.)
	OCCUPIED = 2, # is the center of / is a space that has data for solid terrain
	ENGULFED = 3, # completely engulfed by surrounding solid terrain despite not itself being distinct solid terrain.
		# (For example, if a tile is surrounded on all sides by rhombdo tiles.)
}

# !!! very temporary for terrain rendering testing, a proper place for substance data should be set up later.
enum SUBSTANCE {
	AIR,
	WERIUM,
	FERRIUM,
	FOAM,
}
