#pragma once

#include "godot_cpp/variant/vector2.hpp"
#include "godot_cpp/classes/ref_counted.hpp"

#include <cstdint>
#include <vector>

namespace world_utils {

namespace TERRTILE_SHAPE {
	enum : unsigned char {
		EMPTY = 0,
		FULL,
		CUBIC_OCTREE,
		RHOMBDO_BIG, 
		RHOMBDO_MINI,
		DIAG_HEX,
		TERRACE,
		POWDER,
		MARCH_SIMPLE,
		MARCH_SMOOTH,
		SLOPESTITCH, //(likely won't be implemented unless march stuff doesn't work well)
		NO_DATA = 255,
	};
}

// TODO probably store substance/material 1-per-tile outside of this dataformat struct.
union TERRTILE_DATAFORMAT {
	struct EMPTY {};
	struct FULL {};
	struct CUBIC_OCTREE {
		// TODO [+ however the cubic octree data stuff should be stored]
	};
	struct RHOMBDO_BIG {};
	struct RHOMBDO_MINI {
		unsigned char states = 0b1111; //(bitstates storing whether each of the 4 mini rhombdos is present)
	};
	struct DIAG_HEX {
		unsigned char orientation = 0; //(orientation can be four possible rotations)
	};
	struct TERRACE {};
	struct MARCH_SIMPLE {
		unsigned char states = 0b00000000; //(represents the states of the 8 corners used for meshing.)
	};
	struct MARCH_SMOOTH {
		// TODO (8 [int or float, not sure which yet] scalars)
	};
	/*struct SLOPESTITCH {
		float weight = 0.5;
		godot::Vector2 normal = godot::Vector2();
	};*/
	/*struct SLOPESTITCH { // !!! (may update slopestitching to feature multiple layers of material in a tile in the future.)
		std::vector<float> weights = {};
		godot::Vector2 norm = godot::Vector2();
	};*/
	// (... to be continued)
	struct NO_DATA {};
};

struct TERRTILE_MESHCACHE_SECTION {
};

// !!! something roughly like this may be used for the position of immobile structure stuff within a chunk:
struct [[nodiscard]] StructurePos {
	union {
		struct {
			uint8_t x;
			uint8_t y;
			uint8_t z;
		};

		uint8_t coord[3] = {0};
	};
};

void _toolfunc_gen_voxel_dist_shells();

extern const std::vector<std::vector<godot::Vector3i>> VOXEL_DIST_SHELLS;

/*class WorldUtils {
	public:
		WorldUtils(const WorldUtils& obj) = delete;
		void operator=(const WorldUtils& obj) = delete;
		
		static WorldUtils& get_instance(){
			static WorldUtils world_utils_inst_ptr;
			return world_utils_inst_ptr;
		}
	
	private:
		WorldUtils(){
			testval = 314;
		}
		
	
	public:
		int testval;
		int undefinedint;
};*/

}