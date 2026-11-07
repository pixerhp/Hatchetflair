/*  WORLD_DATA OVERVIEW
    Defines and stores chunks and other world data for shared use across multiple scripts.
*/

#pragma once

#include "concurrent_map_template.hpp"
#include "godot_cpp/variant/vector3i.hpp"

#include <cstdint>


const int DATA_CHUNK_LEN = 16;
const int TERRAIN_MESH_CHUNK_LEN = 32;
const int TERRAIN_MESH_SUBCHUNK_LEN = 4;

namespace TerrtileShape { 
    enum {
        EMPTY,
        CUBIC, //(some combination of 8 mini cubes.)
		RHOMBDO_BIG, 
		RHOMBDO_MINI,
		DIAG_HEX_COL,
		TERRACE,
		POWDER,
		MARCH, //(centered weights, each tri blends 3 mat textures, weight 0 MARCH instead of EMPTY to fill slope gaps)
		NO_DATA,
    };
}

struct TerrTile {
    uint8_t shape = TerrtileShape::NO_DATA;
    uint8_t shape_data = 0b00000000;
    uint16_t substance_id = 0;
};

struct StructurePart {
    // [what kind of thing the structure part is]
    // [other data about it, maybe like what it's made up of or its connection shape with surrounding stuff?]
};

struct WorldChunk {
    TerrTile terrtiles[DATA_CHUNK_LEN][DATA_CHUNK_LEN][DATA_CHUNK_LEN];
    // [liquids?]
    //std::vector<StructurePart> structure_parts;
    // ... [plants if they're not considered structures?, buried objects maybe?]
};
using WorldChunksMap = ConcurrentMap<godot::Vector3i, WorldChunk>;
extern template class ConcurrentMap<godot::Vector3i, WorldChunk>;

extern WorldChunksMap world_chunks_map;
