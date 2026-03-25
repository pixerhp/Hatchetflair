#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector3i.hpp"

#include <cstdint>
#include <map>
#include <variant>
#include <random>

#include "world_utils.hpp"

//inline int xyz_to_t

class WorldChunk {
	public:
		static const int T_LENGTH = 16;
		static const int T_COUNT = T_LENGTH * T_LENGTH * T_LENGTH;

		godot::Vector3i chunk_coords = godot::Vector3i();
		std::uint64_t world_seed = 0;
		unsigned char terrtile_shapes[64][64];
		world_utils::TERRTILE_DATAFORMATS terrtile_data[64][64];
		// !!! node references?

		// !!! cache 4x4x4 tile pieces of the chunk mesh, so that when only a small part changes, less remeshing work has to be done?

	public:
		godot::Error generate();
};

class WorldChunksManager : public godot::RefCounted {
	GDCLASS(WorldChunksManager, RefCounted)

	protected:
		static void _bind_methods();
	
	public:
		std::map<godot::Vector3i, WorldChunk> chunks_map = {};
	
	public:
		WorldChunksManager() = default;
		~WorldChunksManager() override = default;

		void test_function();

		godot::Vector3i get_nearest_unloaded(godot::Vector3i from, int count_limit = -1);
		//Vector3i get_nearest_unloaded_by_cubeshell(Vector3i from, int count_limit = -1);
		std::vector<godot::Vector3i> get_loaded_beyond_r(godot::Vector3i from, float radius);
		std::vector<godot::Vector3i> get_loaded_beyond_cubeshell(godot::Vector3i from, float radius);
		godot::Error checkdo_load(godot::Vector3i where);
		godot::Error checkdo_unload(godot::Vector3i where);
		godot::Error generate(godot::Vector3i where);
		godot::Error remeshify(godot::Vector3i where, uint64_t piece_bits);	
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
