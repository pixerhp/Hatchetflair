#pragma once

#include "godot_cpp/variant/vector2.hpp"

#include <cstdint>
#include <vector>

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

namespace TERRTILE_DATAFORMAT {
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
}


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
