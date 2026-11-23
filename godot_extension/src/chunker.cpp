#include "chunker.hpp"
#include "gde.hpp"

#include "chunk_load_utils.hpp"
#include "chunk_mesh_utils.hpp"
#include "world_data.hpp"

#include <algorithm>
#include <optional>
#include <utility>
#include <vector>

#include <godot_cpp/variant/typed_array.hpp>
#include "godot_cpp/variant/utility_functions.hpp"
#include "godot_cpp/variant/vector3i.hpp"

godot::Array GDE::chunker_get_load_work(godot::Vector3i from_chuord, int max_onload, int max_offload) {
	godot::TypedArray<godot::Vector3i> onload_tasks = {};
	if(max_onload == -1) {
		max_onload = INT_MAX;
	} else {
		if(max_onload < -1) {
			max_onload = 0;
		}
		onload_tasks.reserve(max_onload);
	}
	godot::TypedArray<godot::Vector3i> offload_tasks = {};
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

	godot::Array result;
	result.push_back(godot_onload_array);
	result.push_back(godot_offload_array);
	return result;
}

void GDE::chunker_onload_chunk(godot::Vector3i chuord) {
	if (world_chunks_map.contains(chuord)) {
		godot::UtilityFunctions::push_error(
			"Attempted to onload chunk that already exists: (", chuord, "), this is likely unintended behavior."
		);
	}
	WorldChunk new_world_chunk;
	if (!chunk_mesh_utils::create_test_mesh(rendering_server, chuord, new_world_chunk)) { // !!! double check this later
		return;
	}
	//new_world_chunk.generate();
	world_chunks_map.insert_or_assign(std::pair(chuord, std::move(new_world_chunk)));
}

void GDE::chunker_offload_chunk(godot::Vector3i chuord) {
	const std::optional<WorldChunk> world_chunk = world_chunks_map.get(chuord);
	if (world_chunk.has_value()) {
		if (!chunk_mesh_utils::free_test_mesh(rendering_server, *world_chunk)) { // !!! double check this later
			return;
		}
	}
	world_chunks_map.erase(chuord);
}

void chunker::placeholder_unique_function() {
}
