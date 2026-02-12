#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/variant/variant.hpp"

#include <cstdint>

using namespace godot;

class WorldChunk {
	public:
		std::uint64_t chunk_coords[3];
		std::uint64_t seed;
		unsigned char tile_shapes[4096];

		Error generate();
};


class ExampleClass : public RefCounted {
	GDCLASS(ExampleClass, RefCounted)

protected:
	static void _bind_methods();

public:
	ExampleClass() = default;
	~ExampleClass() override = default;

	void print_type(const Variant &p_variant) const;
};
