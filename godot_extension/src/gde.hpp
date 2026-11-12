/*	GDE OVERVIEW
	Handles the GDE singleton, 
	which acts as a bridge between this GDExtension's functionality and the Godot side of the project.
*/

#pragma once

#include "godot_cpp/classes/object.hpp"
#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/vector3i.hpp"

class GDE : public godot::Object {
	GDCLASS(GDE, Object)

protected:
	static void _bind_methods();

public:
	void test_function();
	void initialize_chunk_load_utils(float new_chunk_onload_radius, float new_chunk_offload_radius);
	godot::Array get_chunk_lengths();
	void filer_save_chunks();
	void filer_load_chunks();
	void filer_save_all();
	godot::Array chunker_get_load_work();
	void chunker_onload_chunk(godot::Vector3i chunk_coords);
	void chunker_offload_chunk(godot::Vector3i chunk_coords);
};

//extern GDE *gde_singleton;
