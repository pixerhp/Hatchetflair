#include "chunks_manager.hpp"
#include "world_utils.hpp"
#include <random>

void WorldChunk::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("generate"), &WorldChunk::generate);
}

Error WorldChunk::generate() {
	unsigned seed = std::chrono::system_clock::now().time_since_epoch().count();
    std::mt19937 rand_int_generator(seed); // Mersenne Twister engine
	std::uniform_int_distribution<int> dist(0, 1); // Random int range
	for (int i = 0; i < 4096; i++) {
		tile_shapes[i] = dist(rand_int_generator);
	}
	return OK;
}


void WorldChunksManager::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("example_function"), &WorldChunksManager::example_function);
}

void WorldChunksManager::example_function() {
	print_line("Hello from WorldChunksManager!");
}




/*void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	print_line(vformat("Type: %d", p_variant.get_type()));
}*/
