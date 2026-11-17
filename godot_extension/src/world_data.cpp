#include "world_data.hpp"

#include "gde.hpp"

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

// !!! the way that this works (+ with the init func) is intruiging; 
// learn more about it, check through it, and clean it up later:
godot::RID &get_chunks_render_scenario() { 
	static godot::RID chunks_render_scenario;
	return chunks_render_scenario;
}

template class ConcurrentMap<godot::Vector3i, WorldChunk>;
WorldChunksMap world_chunks_map;

void GDE::initialize_chunks_render_scenario(godot::RID scenario) {
	if (scenario.is_valid()) {
		get_chunks_render_scenario() = scenario;
	} else {
		godot::UtilityFunctions::push_error("Failed to initialize chunk render scenario, provided scenario is invalid.");
	}
}

godot::Array GDE::get_chunk_lengths() {
	godot::Array chunk_lengths;
	chunk_lengths.append(WORLD_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_SUBCHUNK_LEN);
	return chunk_lengths;
}
