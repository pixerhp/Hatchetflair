extends Node


const CHUNK_WIDTH: int = 16
const CHUNK_TILES_COUNT: int = CHUNK_WIDTH**3

# Current loaded world's data/settings:
var world_name: String = ""
var world_seed: int = 0
# !!! var ocean_height

enum BIOME {
	NO_BIOME,
}

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
enum TILE_FOPAQ { # ("fopaq" from "force to be opaque".)
	DO_TRANSPARENCY = 0,
	FORCE_OPAQUE = 1,
}
# !!! 1 bit enum, or a 1 bit data increase for an existing enum, is available.

# Precalculated bitstates values for each of 3^3 (27) chunks in standard hzz order (all - to all +),
# regarding which of their TPs either are contained in or directly neighbor the central chunk.
# !!! test whether you can set this to const instead of var, the related bug may or may not be fixed.
var CHUNK_VICINITY_TP_BITSTATES: Array[PackedByteArray] = [
	# Bottom layer:
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b10000000], # corner
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b11110000], # edge
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00010000], # corner
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b10001000, 0b10001000], # edge
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b11111111, 0b11111111], # face
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00010001, 0b00010001], # edge
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00001000, 0b00000000], # corner
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00001111, 0b00000000], # edge
	[0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000001, 0b00000000], # corner
	# Middle layer:
	[0b00000000, 0b10000000, 0b00000000, 0b10000000, 0b00000000, 0b10000000, 0b00000000, 0b10000000], # edge
	[0b00000000, 0b11110000, 0b00000000, 0b11110000, 0b00000000, 0b11110000, 0b00000000, 0b11110000], # face
	[0b00000000, 0b00010000, 0b00000000, 0b00010000, 0b00000000, 0b00010000, 0b00000000, 0b00010000], # edge
	[0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000, 0b10001000], # face
	[0b11111111, 0b11111111, 0b11111111, 0b11111111, 0b11111111, 0b11111111, 0b11111111, 0b11111111], # center
	[0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001, 0b00010001], # face
	[0b00001000, 0b00000000, 0b00001000, 0b00000000, 0b00001000, 0b00000000, 0b00001000, 0b00000000], # edge
	[0b00001111, 0b00000000, 0b00001111, 0b00000000, 0b00001111, 0b00000000, 0b00001111, 0b00000000], # face
	[0b00000001, 0b00000000, 0b00000001, 0b00000000, 0b00000001, 0b00000000, 0b00000001, 0b00000000], # edge
	# Top layer:
	[0b00000000, 0b10000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # corner
	[0b00000000, 0b11110000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # edge
	[0b00000000, 0b00010000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # corner
	[0b10001000, 0b10001000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # edge
	[0b11111111, 0b11111111, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # face
	[0b00010001, 0b00010001, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # edge
	[0b00001000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # corner
	[0b00001111, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # edge
	[0b00000001, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000], # corner
]


class Chunk:
	# Non-content data:
	var associated_nodes_refs: Array[Object] = []
		# Stores references to associated scene tree nodes (meshes, collisions, etc.) for quick access.
	var cc: Vector3i = Vector3i(0,0,0)
		# For static chunks, specifies where in the world this chunk is located relative to the origin chunk.
		# For mobile chunks, specifies ccoords relative to the associated group's origin chunk.
	
	# Mesh/collision generation related:
	var lod_type: int = CHUNK_LOD.MID_QUALITY
	
	# NOTE: How TerrainPiece's and terrain bitstates PackedByteArray's are ordered guide:
	# Each chunk has 64 (4*4*4) TerrainPiece objects.
	# In (h,z1,z2) format, they can be considered to range from TP (0,0,0) to TP (3,3,3) (opposite corners.)
	# z2 is incremented from 0-3 and then reset back to 0 for each time z1 gets incremented.
		# Ex. (..., (0,0,2), (0,0,3), (0,1,0), (0,1,1), ...)
	# h is incremented similarly for after each loop of z1.
		# Ex. (..., (0,3,2), (0,3,3), (1,0,0), (1,0,1), ...)
	# Using that method of ordering TerrainPiece's, 64 bitstates are stored across 8 bytes of a PackedByteArray,
	# where the least-significant bit of the first byte represents the first TerrainPiece,
	# the second-least-significant bit of the first byte represents the second TerrainPiece, etc.
		# Ex. TP (1,2,3) would be represented by the 4th-least-significant bit of PackedByteArray[3] (4th byte.)
	
	# Content data:
	var biome: int = BIOME.NO_BIOME
		# A chunk's biome is partially dependant on its content, and thus can be inderectly modified by the player.
	var terrain_pieces: Array[TerrainPiece] = []
	var tp_is_loaded_bitstates: PackedByteArray = []
		# Bitstates for whether each TerrainPiece has its data currently loaded.
	var tp_is_atm_bitstates: PackedByteArray = []
		# Bitstates for whether each TerrainPiece is known to be fully empty/atmosphere.
		# A known-to-be-empty TerrainPiece can stay unloaded to save on RAM, 
		# and if eventually fully loaded, doesn't need to check/open associated save-files to load it.
	var tp_determs_uptodate: Array[PackedByteArray] = [[], [], [], [],]
		# Elements in the outer array represent the different determinable types,
		# (occupiednesses, fluid flow directions, solid terrain stabilities, mesh fopaqs,)
		# each containing a TP bitmask PackedByteArray.
	# !!! var terrain_objects
		# A list of lodged/embedded objects in terrain, such as rocks, etc.
		# !!! May either store the actual objects, pointers to nodetree objects, or otherwise.
	# !!! var structures
		# Stores data related to all structures associated with this chunk, I'm not sure of the format yet.
		# Structures fall along a finer grid than terrain tiles (probably 1/4-metrins, aka 1/256 of a chunk,)
		# and don't exist on a per-grid-volume basis like solid terrain does with tiles.
		# Structure pieces may consist of a variety of shapes/sizes.
	
	func _init(in_cc: Vector3i):
		associated_nodes_refs.clear()
		cc = in_cc
		reset_terrain_pieces()
	
	func zeroify_determstates(
		affected_tps: PackedByteArray, 
		determs_to_zeroify: Array[bool] = [true, true, true, true],
	):
		for i in 8:
			for j in tp_determs_uptodate.size():
				if determs_to_zeroify[j] == true:
					tp_determs_uptodate[j][i] &= ~ affected_tps[i]
		return
	func zeroify_determstates_single(
		tp_i: int, 
		determs_to_zeroify: Array[bool] = [true, true, true, true],
	):
		for j in tp_determs_uptodate.size():
			if determs_to_zeroify[j] == true:
				tp_determs_uptodate[j][tp_i/8] &= ~ (0b00000001 << posmod(tp_i, 8))
		return
	
	func reset_terrain_pieces():
		# Reset the stored TerrainPiece objects:
		terrain_pieces.clear()
		terrain_pieces.resize(4**3)
		terrain_pieces.fill(TerrainPiece.new())
		# Reset data variables associated with terrain:
		biome = BIOME.NO_BIOME
		tp_is_atm_bitstates.resize(8); tp_is_atm_bitstates.fill(0b00000000)
		tp_is_loaded_bitstates.resize(8); tp_is_loaded_bitstates.fill(0b00000000)
		tp_determs_uptodate.resize(4)
		for i in tp_determs_uptodate.size():
			tp_determs_uptodate[i].resize(8)
			tp_determs_uptodate[i].fill(0b00000000)
	
	# A chunk's terrain data separated into 64 (4*4*4) TerrainPiece's (each containing 64 (4*4*4) tiles,)
	# As then individual TerrainPiece's can be loaded/unloaded or have their data calculated/updated,
	# rather then the whole chunk every time.
	class TerrainPiece:
		# Unique data:
		var tiles_shapes: PackedByteArray = [] 
			# Each tile's solid terrain's shape-type.
		# !!! var tiles_shapedatas: Array = [] 
			# Stores terrain shape-type dependant additional data (potentially including slopes, heights, etc.) 
		var tiles_substances: PackedInt32Array = []
			# Each tile's solid terrain's substance.
		# !!! var tiles_attachdatas: Array = []
			# Stores things attached/covering the solid terrain, 
			# such as paint/dye, a decal, plants growing on / out of the associated terrain, etc.
		# !!! liquid_substances variables, specifically which substances in order of layer height,
			# !!! and the heights of said liquid layers.
		
		# Determinable data, chached for quick access:
		var tiles_determinables: PackedByteArray = []
			# Each byte represents 1 tile: 
			# 2 bits for occupiednesses, 2 bits for fluid flow directions, 
			# 2 bits for solid terrain stabilities, 1 bit for mesh fopaqs, 1 currently unused bit.
	
	# ONLY generates natural terrain/structues, doesn't zeroify determs / update nodes / remesh / etc.
	func generate_natural(in_seed: int = WorldUtils.world_seed, in_cc: Vector3i = cc):
		
		# !!! write terrain/other generation code later
		
		pass

func tp_i_from_hzz(hzz: Vector3i) -> int:
	return (hzz[0] * 16) + (hzz[1] * 4) + (hzz[2])
func tp_hzz_from_i(i: int) -> Vector3i:
	return Vector3i(posmod(i/16, 4), posmod(i/4, 4), posmod(i, 4))

class ChunksGroup:
	var chunks: Array[Chunk] = []
	var cc_to_i: Dictionary = {}
		# chunk coordinates to chunks array index.
	func refresh_cc_to_i():
		cc_to_i.clear()
		for i in chunks.size():
			cc_to_i[chunks[i].ccoords] = i
		return
	
	# Regarding a full chunk's TPs + the immediately surrounding TPs of neighboring chunks.
	func zeroify_vicinity_determstates_chunk(
		cc: Vector3i, 
		determs_to_zeroify: Array[bool] = [true, true, true, true],
	):
		var targ_cc: Vector3i = Vector3i.ZERO
		var targ_chunk_i: int = 0
		for i in (3**3):
			targ_cc = cc + Vector3i(posmod(i/9, 3) - 1, posmod(i/3, 3) - 1, posmod(i, 3) - 1)
			targ_chunk_i = cc_to_i.get(targ_cc, -1)
			if targ_chunk_i != -1:
				chunks[targ_chunk_i].zeroify_determstates(
					WorldUtils.CHUNK_VICINITY_TP_BITSTATES[i], 
					determs_to_zeroify,
				)
		return
	# Regarding a single TP + the immediately surrounding TPs (some which may be in neighboring chunks.)
	func zeroify_vicinity_determstates_tp(
		cc: Vector3i, 
		tp_i: int,
		determs_to_zeroify: Array[bool] = [true, true, true, true],
	):
		var tp_c: Vector3i = WorldUtils.tp_hzz_from_i(tp_i)
		var targ_tp_c: Vector3i = Vector3i.ZERO
		var targ_cc: Vector3i = Vector3i.ZERO
		var targ_chunk_i: int = 0
		for i in (3**3):
			targ_tp_c = tp_c + Vector3i(posmod(i/9, 3) - 1, posmod(i/3, 3) - 1, posmod(i, 3) - 1)
			targ_cc = Vector3i(
				( (cc[0]-1) if (targ_tp_c[0]<0) else (cc[0]) ) if (targ_tp_c[0]<4) else (cc[0]+1), 
				( (cc[1]-1) if (targ_tp_c[1]<0) else (cc[1]) ) if (targ_tp_c[1]<4) else (cc[1]+1),
				( (cc[2]-1) if (targ_tp_c[2]<0) else (cc[2]) ) if (targ_tp_c[2]<4) else (cc[2]+1),
			)
			targ_chunk_i = cc_to_i.get(targ_cc, -1)
			if targ_chunk_i == -1:
				continue
			targ_tp_c = Vector3i(posmod(targ_tp_c[0], 4), posmod(targ_tp_c[1], 4), posmod(targ_tp_c[2], 4))
			chunks[targ_chunk_i].zeroify_determstates_single(
				WorldUtils.tp_i_from_hzz(targ_tp_c),
				determs_to_zeroify,
			)
		return
	
	# Generally call the specialized load chunk funcs instead for regular use.
	func load_chunk_generic(
		cc: Vector3i, 
		chunks_group_is_mobile: bool, # (false for is static.)
		identifier: String = ""
	) -> Error:
		var chunk_index: int = cc_to_i.get(cc, -1)
		if chunk_index == -1:
			chunk_index = chunks.size()
			cc_to_i[cc] = chunk_index
			chunks.append(WorldUtils.Chunk.new(cc))
		
		if chunks_group_is_mobile:
			chunks[chunk_index] = FM.load_chunk(cc, true, identifier)
		else:
			chunks[chunk_index] = FM.load_chunk(cc, false)
		
		# Regardless of the load's success, the chunk has been affected thus would require this.
		zeroify_vicinity_determstates_chunk(cc)
		
		if FM.load_error != OK:
			return FAILED
		else:
			return OK

# "Static chunks" refers to the chunks that define the whole world, which everything else is
# relative to. Every part of the playable space is represented by an associated static chunk,
# even empty/only-atmosphere space.
# There only needs to be one static chunks group object.
class StaticChunksGroup:
	extends ChunksGroup
	
	func _init():
		pass
	
	func save_chunk_by_i(chunk_index: int) -> Error:
		return FM.save_chunk(chunks[chunk_index], false)
	func save_chunk_by_cc(cc: Vector3i) -> Error:
		var chunk_index: int = cc_to_i.get(cc, -1)
		if chunk_index != -1:
			return save_chunk_by_i(chunk_index)
		else:
			return FAILED
	func save_all_chunks() -> Error:
		var err: Error = OK
		for i in chunks.size():
			if save_chunk_by_i(i) == FAILED:
				err = FAILED
		return err
	
	func load_chunk(cc: Vector3i) -> Error:
		return load_chunk_generic(cc, false)

# Distinct mobile terrain/structures which move separately-from/ontop-of the static world, 
# potentially including player-built boats, airships (etc,) rolling boulders, floating islands (etc,)
# may each be represented with an associated mobile chunks group. As those things are limited in size,
# MCGs only load/have chunks relavent to the thing that they represent.
class MobileChunksGroup:
	extends ChunksGroup
	var identifier: String = ""
		# Used by the ChunksManager to help differentiate/access different mobile chunk groups.
	var controller_node: Node3D
		# A reference to the 3D node which parents all of the group's chunk nodes.
		# For example, if the whole group needs to move together, then this node is the only one that moves.
	
	func _init(in_identifier: String):
		identifier = in_identifier
		return
	
	func save_chunk_by_i(chunk_index: int) -> Error:
		return FM.save_chunk(chunks[chunk_index], true, identifier)
	func save_chunk_by_cc(cc: Vector3i) -> Error:
		var chunk_index: int = cc_to_i.get(cc, -1)
		if chunk_index != -1:
			return save_chunk_by_i(chunk_index)
		else:
			return FAILED
	func save_all_chunks() -> Error:
		var err: Error = OK
		for i in chunks.size():
			if save_chunk_by_i(i) == FAILED:
				err = FAILED
		return err
	
	func load_chunk(cc: Vector3i) -> Error:
		return load_chunk_generic(cc, true, identifier)
