#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/variant.hpp"
#include "godot_cpp/variant/vector3i.hpp"

#include <map>

class GDE : public godot::RefCounted {
	GDCLASS(GDE, RefCounted)

protected:
	static void _bind_methods();

public:
	std::map<godot::Vector3i, godot::Variant> chunks;

	void test_function();
	void filer_save_chunks();
	void filer_load_chunks();
	void filer_save_all();
	godot::Array chunker_get_load_work();
	void chunker_onload_chunk(godot::Vector3i chunk_coords);
	void chunker_offload_chunk(godot::Vector3i chunk_coords);
};

//extern GDE *gde_singleton;
