#include "chunks_manager.hpp"

//////////////// v WorldChunk v ////////////////

bool is_4x4_menger_sponge(int x, int y, int z) {
	x = abs(x); y = abs(y); z = abs(z);
	while((x > 0) and (y > 0) and (z > 0)) {
		if(((x%4 == 1)or(x%4 == 2)) and ((y%4 == 1)or(y%4 == 2)) and ((y%4 == 1)or(y%4 == 2))) {
			return false;
		}
		x /= 4; y /= 4; z /= 4;
	}
	return true;
}

void WorldChunk::regenerate_terrtiles() {
	for(int y=0; y<T_LEN; y++){ for(int z=0; z<T_LEN; z++){ for(int x=0; x<T_LEN; x++){
		if(is_4x4_menger_sponge(x, y, z)) {
			terrtile_shapes[x][y][z] = world_utils::TERRTILE_SHAPE::FULL;
		} else {
			terrtile_shapes[x][y][z] = world_utils::TERRTILE_SHAPE::EMPTY;
		}
	}}}
	return;
}

//////////////// v WorldChunksManager v ////////////////

void WorldChunksManager::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("test_function"), &WorldChunksManager::test_function);
	godot::ClassDB::bind_method(godot::D_METHOD("chunk_loading_routine", "from_coords", "chuords_offset", "load_radius", "unload_radius"), &WorldChunksManager::chunk_loading_routine);
}

// For miscellaneous testing/debugging or usage of toolfuncs:
void WorldChunksManager::test_function() {
	godot::print_line("Hello from WorldChunksManager's test func!");
	//world_utils::_toolfunc_gen_voxel_dist_shells();
	//chunks_map[godot::Vector3i(0, 0, 0)] = WorldChunk();
	/*std::vector<godot::Vector3i> chunks_found = WorldChunksManager::get_unloaded_before_or_at_cubeshell(godot::Vector3i(0,0,0), 5.0, 200);
	for(int i = 0; i < chunks_found.size(); i++) {
		godot::print_line(chunks_found[i]);
	}*/
}

godot::Array WorldChunksManager::chunk_loading_routine(godot::Vector3 from_coords, godot::Vector3i chuords_offset, float load_radius, float unload_radius) {
	const godot::Vector3i from_chuords = godot::Vector3i(from_coords) + chuords_offset;
	std::vector<godot::Vector3i> chunks_to_load = WorldChunksManager::get_unloaded_before_or_at_dist(from_chuords, load_radius, 16);
	std::vector<godot::Vector3i> chunks_to_unload = WorldChunksManager::get_loaded_beyond_dist(from_chuords, unload_radius, 16);
	
	godot::Array return_data = godot::Array();

	// !!! load chunks, unload chunks, and return a bunch of data (nodes to remove, meshing data, etc) back to the Godot side.

	return(return_data);
}


std::vector<godot::Vector3i> WorldChunksManager::get_unloaded_before_or_at_dist(godot::Vector3i from_chuords, float radius, int result_limit) {
	if(result_limit <= 0) {return{};}
	const int64_t radius_sqrd_flr = static_cast<int64_t>(floor(radius*radius));
	std::vector<godot::Vector3i> results = {};
	for(int shell_index = 0; shell_index < world_utils::VOXEL_DIST_SHELLS.size(); shell_index++) {
		const auto &shell = world_utils::VOXEL_DIST_SHELLS[shell_index];
		if(shell[0].length_squared() > radius_sqrd_flr) {
			break;
		}
		for (int subshell_index = 0; subshell_index < shell.size(); subshell_index++) {
			godot::Vector3i guess = from_chuords + shell[subshell_index];
			if(not chunks_map.contains(guess)) {
				results.push_back(guess);
				if(results.size() >= result_limit) {
					return(results);
				}
			}
		}
	}
	return(results);
}

std::vector<godot::Vector3i> WorldChunksManager::get_unloaded_before_or_at_cubeshell(godot::Vector3i from_chuords, int radius, int result_limit) {
	if(result_limit <= 0) {return{};}
	radius = abs(radius);
	std::vector<godot::Vector3i> results = {};
	results.reserve(result_limit);

	if(not chunks_map.contains(from_chuords)) {
		results.push_back(from_chuords);
	}
	if((radius == 0) or (results.size() >= result_limit)) {
		return(results);
	}

	for(int octant_length = 1; octant_length <= radius; octant_length++) {
		int x, y, z; x = y = z = octant_length * -1;
		for(int i = 0; i < ((24*(octant_length-3)*(octant_length-1))+26); i++) {
			if(not chunks_map.contains(from_chuords + godot::Vector3i(x, y, z))) {
				results.push_back(from_chuords + godot::Vector3i(x, y, z));
				if(results.size() >= result_limit) {
					return(results);
				}
			}
			// Update x, y, z for the next check:
			if(abs(y) == octant_length) { //(top/bottom full-square slice)
				if((x == octant_length) and (z == octant_length)) {
					x = z = octant_length * -1;
					y++;
				} else if(x == octant_length) {
					x = octant_length * -1;
					z++;
				} else {
					x++;
				}
			} else { //(middle hollow-square slice)
				if((x == octant_length) and (z == octant_length)) {
					x = z = octant_length * -1;
					y++;
				} else if(abs(z) == octant_length) {
					if(x == octant_length){
						x = octant_length * -1;
						z++;
					} else {
						x++;
					}
				} else if(x == octant_length) {
					x = octant_length * -1;
					z++;
				} else {
					x = octant_length;
				}
			}
		}
	}
	return(results);
}

std::vector<godot::Vector3i> WorldChunksManager::get_loaded_beyond_dist(godot::Vector3i from_chuords, float radius, int result_limit) {
	if(result_limit <= 0) {return{};}
	const int64_t radius_sqrd_flr = static_cast<int64_t>(floor(radius*radius));
	std::vector<godot::Vector3i> results = {};
	if(result_limit != INT32_MAX) {results.reserve(result_limit);}

	for(const auto &pair : chunks_map) {
		godot::Vector3i relative_chuords = pair.first - from_chuords;
		if(relative_chuords.length_squared() > radius_sqrd_flr) {
			results.push_back(pair.first);
			if(results.size() >= result_limit) {
				return(results);
			}
		}
	}
	return(results);
}

std::vector<godot::Vector3i> WorldChunksManager::get_loaded_beyond_cubeshell(godot::Vector3i from_chuords, int radius, int result_limit) {
	if(result_limit <= 0) {return{};}
	radius = abs(radius);
	std::vector<godot::Vector3i> results = {};
	if(result_limit != INT32_MAX) {
		results.reserve(result_limit);
	}
	for(const auto &pair : chunks_map) {
		godot::Vector3i rel_chuords = pair.first - from_chuords;
		for(int axis = 0; axis < 3; axis++) {
			if(abs(rel_chuords[axis]) > radius) {
				results.push_back(pair.first);
				if(results.size() >= result_limit) {
					return(results);
				}
				break;
			}
		}
	}
	return(results);
}
