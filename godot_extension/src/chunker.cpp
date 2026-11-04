#include "chunker.hpp"

#include "gde.hpp"

godot::Array GDE::chunker_get_load_work() {
	return {};
}

void GDE::chunker_onload_chunk(godot::Vector3i chunk_coords) {
	(void)chunk_coords;
}

void GDE::chunker_offload_chunk(godot::Vector3i chunk_coords) {
	(void)chunk_coords;
}

void chunker::placeholder_unique_function() {
}
