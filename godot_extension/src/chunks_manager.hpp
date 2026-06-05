#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector3i.hpp"

#include <cstdint>
#include <map>
#include <variant>
#include <random>
#include <bitset>

#include "world_utils.hpp"


const godot::Vector3 FAIL_COORDS = godot::Vector3(INFINITY, INFINITY, INFINITY);
const godot::Vector3i FAIL_CHUORDS = godot::Vector3i(INT32_MAX,INT32_MAX,INT32_MAX);

class WorldChunk {
	public:
		static const int T_LEN = 16;
		static const int T_COUNT = T_LEN * T_LEN * T_LEN;
		static const int T_MESHCACHE_LEN = 4; //(needs to be a factor of T_LEN)
		static const int T_MESHCACHE_COUNT = T_MESHCACHE_LEN * T_MESHCACHE_LEN * T_MESHCACHE_LEN;
	public:
		godot::Vector3i chuords = FAIL_CHUORDS;
		std::uint64_t gen_seed = 0; // !!! defaultly set to whatever the current world seed is.
		unsigned char terrtile_shapes[T_LEN][T_LEN][T_LEN];
		world_utils::TERRTILE_DATAFORMATS terrtile_data[T_LEN][T_LEN][T_LEN];
		world_utils::TERRTILE_MESHCACHE_SECTION terrtile_meshcache[T_MESHCACHE_LEN][T_MESHCACHE_LEN][T_MESHCACHE_LEN];
		std::bitset<WorldChunk::T_MESHCACHE_COUNT> terrtile_meshcache_remesh_flags = ~ std::bitset<WorldChunk::T_MESHCACHE_COUNT>();
			//(↑ flags representing which meshcache pieces need remeshing, mostly for later use with tile editing.)
		// !!! store a list of tiles whose meshing was skipped until a surrounding chunk's data was generated?
		// !!! (structures, etc... probably a vector on the heap)
		// !!! (store godot mesh/collision node references?)
	public:
		void regenerate_terrtiles();
		WorldChunk(godot::Vector3i chuords_input) {
			chuords = chuords_input;
		}
};

class WorldChunksManager : public godot::RefCounted {
	GDCLASS(WorldChunksManager, RefCounted)

	protected:
		static void _bind_methods();
	
	public:
		std::map<godot::Vector3i, WorldChunk> chunks_map = {};
		std::map<godot::Vector3i, WorldChunk> remesh_after_load = {};
	
	public:
		WorldChunksManager() = default;
		~WorldChunksManager() override = default;

		void test_function();
		godot::Array chunk_loading_routine(godot::Vector3 from_coords, godot::Vector3i chuords_offset, float load_radius, float unload_radius);

		// !!! func for load materials / generation data / etc from files?
		
		std::vector<godot::Vector3i> get_unloaded_before_or_at_dist(godot::Vector3i from_chuords, float radius, int result_limit = 1);
		std::vector<godot::Vector3i> get_unloaded_before_or_at_cubeshell(godot::Vector3i from_chuords, int radius, int result_limit = 1);
		std::vector<godot::Vector3i> get_loaded_beyond_dist(godot::Vector3i from_chuords, float radius, int result_limit = INT32_MAX);
		std::vector<godot::Vector3i> get_loaded_beyond_cubeshell(godot::Vector3i from_chuords, int radius, int result_limit = INT32_MAX);
		
		godot::Error checkdo_load(godot::Vector3i where_chuords);
		godot::Error checkdo_unload(godot::Vector3i where_chuords);
		godot::Error remeshify_terrtiles(godot::Vector3i where, std::bitset<WorldChunk::T_MESHCACHE_COUNT> meshcache_bitmask); 
};



/*class ExampleClass : public RefCounted {
	GDCLASS(ExampleClass, RefCounted)

protected:
	static void _bind_methods();

public:
	ExampleClass() = default;
	~ExampleClass() override = default;

	void print_type(const Variant &p_variant) const;
};*/
