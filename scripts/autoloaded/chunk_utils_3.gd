extends Node

# The standard chunk length in metrins/tiles.
const CHUNK_LENGTH: int = 16

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
	EMPTY = 0, # no solid terrain, only filled with atmosphere/gas
	ENGULFED = 1, # completely engulfed by surrounding terrain (rather than partially empty) despite having no data
	OCCUPIED = 2, # is the center of / is a space that has data for solid terrain
	SEMI = 3, # for "semi-empty", potentially useful for liquids.
}

enum SUBSTANCE {
	AIR,
	WERIUM,
	FERRIUM,
	FOAM,
}
