#include "chunk_load_utils.hpp"

#include "gde.hpp"

// CAUTION: These are used in multithreading without mutex protection (typically they're only read from),
// but take care to avoid using them during reinitializing (such as due to changing settings) via Godot.
float chunk_onload_radius_squared = 0.5 * 0.5;
float chunk_offload_radius_squared = 0.5 * 0.5;
std::vector<godot::Vector3i> chunk_onload_check_list = {godot::Vector3i(0, 0, 0)};

void GDE::initialize_chunk_load_utils(float new_chunk_onload_radius, float new_chunk_offload_radius) {
	chunk_onload_radius_squared = new_chunk_onload_radius * new_chunk_onload_radius;
	chunk_offload_radius_squared = new_chunk_offload_radius * new_chunk_offload_radius;
}
