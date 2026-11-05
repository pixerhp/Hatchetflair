/*  WORLD_DATA OVERVIEW
    Defines and stores chunks and other world data for shared use across multiple scripts.
*/

#pragma once

#include "godot_cpp/variant/variant.hpp"

#include <map>
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

struct Terrtile {
    uint8_t shape = TerrtileShape::NO_DATA;
    uint8_t shape_data = 0b00000000;
    uint16_t substance_id = 0;
};

//extern std::map<godot::Vector3i, aabbccdd> chunks;
