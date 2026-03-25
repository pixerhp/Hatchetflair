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

void WorldChunksManager::test_function() {
	world_utils::_toolfunc_gen_voxel_dist_shells();
	//godot::print_line(world_utils::VOXEL_DIST_SHELLS[27][0]);
	//print_line("Hello from WorldChunksManager!");
}


/*void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	print_line(vformat("Type: %d", p_variant.get_type()));
}*/
