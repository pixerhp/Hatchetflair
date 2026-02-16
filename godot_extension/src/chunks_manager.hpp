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

class WorldChunk {
	protected:
		static void _bind_methods();

	public:
		static const int T_LENGTH = 16;
		static const int T_COUNT = T_LENGTH * T_LENGTH * T_LENGTH;

		Vector3i chunk_coords = Vector3i();
		std::uint64_t chunk_seed = 0;
		unsigned char terrtile_shapes[4096];
		std::variant<
			TERRTILE_DATAFORMAT::NO_DATA, 
			TERRTILE_DATAFORMAT::EMPTY, 
			TERRTILE_DATAFORMAT::FULL, 
			TERRTILE_DATAFORMAT::WEICENORM
		> terrtile_datas[4096];

	public:
		Error generate();
};

class WorldChunksManager : public RefCounted {
	GDCLASS(WorldChunksManager, RefCounted)

	protected:
		static void _bind_methods();
	
	public:
		WorldChunksManager() = default;
		~WorldChunksManager() override = default;

		std::map<Vector3i, WorldChunk> chunks_map = {};

		void example_function();
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
