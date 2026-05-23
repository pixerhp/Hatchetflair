#include "chunks_manager.hpp"

godot::Error WorldChunk::generate() {
	unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
    std::mt19937 rand_int_generator(seed); // Mersenne Twister engine
	std::uniform_int_distribution<int> dist(1, 2); // Random int range
	for (int i = 0; i < 64; i++) { for (int j = 0; j < 64; j++) {
		terrtile_shapes[i][j] = dist(rand_int_generator);
	}}
	return godot::OK;

}


void WorldChunksManager::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("test_function"), &WorldChunksManager::test_function);
}

// For use in miscellaneous testing:
void WorldChunksManager::test_function() {
	godot::print_line("Hello from WorldChunksManager's test func!");
	//world_utils::_toolfunc_gen_voxel_dist_shells();
	chunks_map[godot::Vector3i(0, 0, 0)] = WorldChunk();
	// chunks_map[godot::Vector3i(1, 0, 0)] = WorldChunk();
	// chunks_map[godot::Vector3i(0, 1, 0)] = WorldChunk();
	// chunks_map[godot::Vector3i(0, 0, 1)] = WorldChunk();
	// chunks_map[godot::Vector3i(-1, 0, 0)] = WorldChunk();
	// chunks_map[godot::Vector3i(0, -1, 0)] = WorldChunk();
	// chunks_map[godot::Vector3i(0, 0, -1)] = WorldChunk();
	for(int i = 0; i < 9; i++) {
		chunks_map[godot::Vector3i((i%3)-1, -1, ((i/3)%3)-1)] = WorldChunk();
	}
	chunks_map[godot::Vector3i(-1, 0, -1)] = WorldChunk();
	godot::print_line("Nearest unloaded chunk test: ");
	godot::print_line(chunks_map.size());
	godot::print_line(WorldChunksManager::get_nearest_unloaded_by_cubeshell(godot::Vector3i(0,0,0), 5));
}

// !!! for get nearest unloaded, consider caching stuff or otherwise so that when situationally acceptable, you skip past an initial bunch of searches.

// (Note: Currently limited to size of hardcoded data.)
godot::Vector3i WorldChunksManager::get_nearest_unloaded_by_dist(godot::Vector3i from_chuords, int check_limit) {
	int search_count = 0;
	godot::Vector3i guess = godot::Vector3i();
	for(int shell_index = 0; shell_index < world_utils::VOXEL_DIST_SHELLS.size(); shell_index++) {
	for(int subshell_index = 0; subshell_index < world_utils::VOXEL_DIST_SHELLS[shell_index].size(); subshell_index++) {
		guess = from_chuords + world_utils::VOXEL_DIST_SHELLS[shell_index][subshell_index];
		if(not chunks_map.contains(guess)) {
			return(guess);
		}
		search_count++;
		if(search_count >= check_limit) {
			goto failcase;
		}
	}}
	failcase:
	return(from_chuords + FAIL_CHUORDS);
}

godot::Vector3i WorldChunksManager::get_nearest_unloaded_by_cubeshell(godot::Vector3i from_chuords, int check_limit) {
	int search_count = 1;
	int shell_layer = 1;
	int corner_len = 0;
	int x = 0, y = 0, z = 0;
	godot::Vector3i guess = godot::Vector3i();
	// 'from_chuords' central chunk check:
	if(!chunks_map.contains(from_chuords)) {
		return(from_chuords);
	}
	if(search_count >= check_limit) {
		goto failcase;
	}
	// shells chunks checking:
	while(true) {
		corner_len = shell_layer;
		x = y = z = corner_len * -1;
		shell_layer++;
		for(int i = 0; i < ((24*(shell_layer-2)*shell_layer)+26); i++) {
			// Check, and increment the search count:
			guess = from_chuords + godot::Vector3i(x, y, z);
			if(not chunks_map.contains(guess)) {
				return(guess);
			}
			search_count++;
			if(search_count >= check_limit) {
				goto failcase;
			}
			// Update x, y, z for the next check:
			if(abs(y) == corner_len) { //(top/bottom full-square slice)
				if((x == corner_len) and (z == corner_len)) {
					x = z = corner_len * -1;
					y++;
				} else if(x == corner_len) {
					x = corner_len * -1;
					z++;
				} else {
					x++;
				}
			} else { //(middle hollow-square slice)
				if((x == corner_len) and (z == corner_len)) {
					x = z = corner_len * -1;
					y++;
				} else if(abs(z) == corner_len) {
					if(x == corner_len){
						x = corner_len * -1;
						z++;
					} else {
						x++;
					}
				} else if(x == corner_len) {
					x = corner_len * -1;
					z++;
				} else {
					x = corner_len;
				}
			}
		}
	}
	failcase:
	return(from_chuords + FAIL_CHUORDS);
}

std::vector<godot::Vector3i> WorldChunksManager::get_loaded_beyond_dist(godot::Vector3i from, float radius) {
	// !!!
	return{};
}

std::vector<godot::Vector3i> WorldChunksManager::get_loaded_beyond_cubeshell(godot::Vector3i from, int radius) {
	// !!!
	return{};
}


/*void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	print_line(vformat("Type: %d", p_variant.get_type()));
}*/
