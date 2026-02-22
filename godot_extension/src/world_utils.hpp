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
		WEICENORM,
		TERRACE,
		CUBIC,
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
	struct WEICENORM {
		std::vector<uint16_t> material_inds = {};
		std::vector<float> weights = {};
		godot::Vector2 norm = godot::Vector2();
	};
	// (... to be continued)
};

void _toolfunc_gen_voxel_dist_shells();

extern const std::vector<std::vector<godot::Vector3i>> voxel_dist_shells;

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