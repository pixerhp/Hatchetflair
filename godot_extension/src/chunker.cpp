#include "chunker.hpp"
#include "gde.hpp"

#include "chunk_load_utils.hpp"
#include "world_data.hpp"

#include <algorithm>
#include <vector>

#include "godot_cpp/variant/vector3i.hpp"
#include <godot_cpp/variant/typed_array.hpp>

godot::Array GDE::chunker_get_load_work(godot::Vector3i from_chuord, int max_onload, int max_offload) {
	std::vector<godot::Vector3i> onload_tasks = {};
	if(max_onload == -1) {
		max_onload = INT_MAX;
	} else {
		if(max_onload < -1) {
			max_onload = 0;
		}
		onload_tasks.reserve(max_onload);
	}
	std::vector<godot::Vector3i> offload_tasks = {};
	if(max_offload == -1) {
		max_offload = INT_MAX;
	} else {
		if(max_offload < -1) {
			max_offload = 0;
		}
		offload_tasks.reserve(max_offload);
	}

	std::vector<godot::Vector3i> existing_chuords = world_chunks_map.keys();

	// Get onload work:
	for(const godot::Vector3i &check_relative : chunk_load_utils::chunk_onload_checks) {
		if(onload_tasks.size() >= max_onload) {
			break;
		}
		godot::Vector3i check_absolute = from_chuord + check_relative;
		if(std::find(existing_chuords.begin(), existing_chuords.end(), check_absolute) == existing_chuords.end()) {
			onload_tasks.push_back(check_absolute);
		}
	}

	// Get offload work:
	for(const godot::Vector3i &chuord : existing_chuords) {
		if(offload_tasks.size() >= max_offload) {
			break;
		}
		if(chuord.distance_squared_to(from_chuord) > chunk_load_utils::chunk_offload_radius_squared) {
			offload_tasks.push_back(chuord);
		}
	}

	// Format the onload/offload work into Godot arrays, and return:
	godot::TypedArray<godot::Vector3i> godot_onload_array;
	for(const godot::Vector3i &chuord : onload_tasks) {
		godot_onload_array.push_back(chuord);
	}
	godot::TypedArray<godot::Vector3i> godot_offload_array;
	for(const godot::Vector3i &chuord : offload_tasks) {
		godot_offload_array.push_back(chuord);
	}
	godot::Array result;
	result.push_back(godot_onload_array);
	result.push_back(godot_offload_array);
	return result;
}

void GDE::chunker_onload_chunk(godot::Vector3i chuord) {
	
}

void GDE::chunker_offload_chunk(godot::Vector3i chuord) {
	
}

void chunker::placeholder_unique_function() {
}
