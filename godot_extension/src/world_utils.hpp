#pragma once

#include "godot_cpp/variant/vector2.hpp"
#include "godot_cpp/classes/ref_counted.hpp"

#include <cstdint>
#include <vector>

namespace world_utils {

namespace TERRTILE_SHAPE {
	enum : unsigned char {
		NO_DATA = 0,
		EMPTY = 1,
		FULL,
		SLOPESTITCH,
		TERRACE,
		CUBIC, //(similar to full, but uses a tileset dependant on adjacent cubic tiles rather than an independant simple texture?)
		BIG_RHOMBDO,
		MINI_RHOMBDOS,
	};
}

union TERRTILE_DATAFORMATS {
	struct NO_DATA {};
	struct EMPTY {};
	struct FULL {
		int material_index = 0;
	};
	struct SLOPESTITCH {
		uint16_t material_inds = 0;
		float weight = 0.5;
		godot::Vector2 normal = godot::Vector2();
	};
	/*struct SLOPESTITCH { // !!! (may update slopestitching to feature multiple layers of material in a tile in the future.)
		std::vector<uint16_t> material_inds = {};
		std::vector<float> weights = {};
		godot::Vector2 norm = godot::Vector2();
	};*/
	// (... to be continued)
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