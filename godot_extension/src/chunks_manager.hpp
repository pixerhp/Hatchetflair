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

using namespace godot;
using namespace world_utils;

//inline int xyz_to_t

class WorldChunk {
	public:
		static const int T_LENGTH = 16;
		static const int T_COUNT = T_LENGTH * T_LENGTH * T_LENGTH;

		Vector3i chunk_coords = Vector3i();
		std::uint64_t world_seed = 0;
		unsigned char terrtile_shapes[64][64];
		TERRTILE_DATAFORMATS terrtile_data[64][64];
		// !!! node references?

		// !!! cache 4x4x4 tile pieces of the chunk mesh, so that when only a small part changes, less remeshing work has to be done?

	public:
		Error generate();
};

class WorldChunksManager : public RefCounted {
	GDCLASS(WorldChunksManager, RefCounted)

	protected:
		static void _bind_methods();
	
	public:
		std::map<Vector3i, WorldChunk> chunks_map = {};
	
	public:
		WorldChunksManager() = default;
		~WorldChunksManager() override = default;

		void example_function();

		Vector3i get_nearest_unloaded(Vector3i from, int count_limit = -1);
			// !!! perhaps cache 'from' and also the found result, so that if the function gets called again with the same 'from' it can resume from where it left off?
		//Vector3i get_nearest_unloaded_by_cubeshell(Vector3i from, int count_limit = -1);
		std::vector<Vector3i> get_loaded_beyond_r(Vector3i from, float radius);
		std::vector<Vector3i> get_loaded_beyond_cubeshell(Vector3i from, float radius);
		Error checkdo_load(Vector3i where);
		Error checkdo_unload(Vector3i where);
		Error generate(Vector3i where);
		Error remeshify(Vector3i where, uint64_t piece_bits);	
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
