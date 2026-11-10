#include "gde.hpp"

#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/utility_functions.hpp"

void GDE::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("test_function"), &GDE::test_function);
	godot::ClassDB::bind_method(godot::D_METHOD("initialize_chunk_load_utils", "new_chunk_onload_radius", "new_chunk_offload_radius"), &GDE::initialize_chunk_load_utils);
	godot::ClassDB::bind_method(godot::D_METHOD("get_chunk_lengths"), &GDE::get_chunk_lengths);
	godot::ClassDB::bind_method(godot::D_METHOD("filer_save_chunks"), &GDE::filer_save_chunks);
	godot::ClassDB::bind_method(godot::D_METHOD("filer_load_chunks"), &GDE::filer_load_chunks);
	godot::ClassDB::bind_method(godot::D_METHOD("filer_save_all"), &GDE::filer_save_all);
	godot::ClassDB::bind_method(godot::D_METHOD("chunker_get_load_work"), &GDE::chunker_get_load_work);
	godot::ClassDB::bind_method(godot::D_METHOD("chunker_onload_chunk", "chunk_coords"), &GDE::chunker_onload_chunk);
	godot::ClassDB::bind_method(godot::D_METHOD("chunker_offload_chunk", "chunk_coords"), &GDE::chunker_offload_chunk);
}

void GDE::test_function() {
	godot::UtilityFunctions::print("Hello from the GDE test function!");
}
