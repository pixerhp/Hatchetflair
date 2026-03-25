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
	//world_utils::_toolfunc_gen_voxel_dist_shells();
	//godot::print_line(world_utils::VOXEL_DIST_SHELLS[27][0]);
	//godot::print_line("Hello from WorldChunksManager!");
}

// !!! consider caching stuff or otherwise so that when situationally acceptable, you skip past an initial bunch of searches.
godot::Vector3i WorldChunksManager::get_nearest_unloaded(godot::Vector3i from, int count_limit) {
	int search_count = 0;
	godot::Vector3i guess = godot::Vector3i();
	for(int shell_index = 0; shell_index < world_utils::VOXEL_DIST_SHELLS.size(); shell_index++) {
	for(int subshell_index = 0; subshell_index < world_utils::VOXEL_DIST_SHELLS[shell_index].size(); subshell_index++) {
		guess = from + world_utils::VOXEL_DIST_SHELLS[shell_index][subshell_index];
		if(chunks_map.contains(guess)) {
			return(guess);
		} else if (count_limit > 0) {
			search_count++;
			if(search_count >= count_limit) {
				goto failcase;
			}
		}
	}}
	failcase:
	return(from + godot::Vector3i(INT32_MAX,INT32_MAX,INT32_MAX));
}





/*void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	print_line(vformat("Type: %d", p_variant.get_type()));
}*/
