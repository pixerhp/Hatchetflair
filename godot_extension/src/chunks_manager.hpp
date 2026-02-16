#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"

#include "godot_cpp/variant/vector3i.hpp"

#include <cstdint>
#include <map>

using namespace godot;

class WorldChunk {
	public:
		Vector3i chunk_coords;
		std::uint64_t chunk_seed;
		unsigned char tile_shapes[4096];

		Error generate();
};

extern std::map<Vector3i, WorldChunk> world_chunks;

class WorldChunksManager : public RefCounted {
	GDCLASS(WorldChunksManager, RefCounted)

	protected:
		static void _bind_methods();
	
	public:
		WorldChunksManager() = default;
		~WorldChunksManager() override = default;

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
