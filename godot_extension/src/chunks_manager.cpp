#include "chunks_manager.hpp"
#include "world_utils.hpp"
#include <random>

Error WorldChunk::generate() {
	unsigned random_integer_seed = std::chrono::system_clock::now().time_since_epoch().count();
    std::mt19937 rand_int_generator(random_integer_seed); // Mersenne Twister engine
	std::uniform_int_distribution<int> dist(0, 1); // Random int range
	for (int i = 0; i < 4096; i++) {
		tile_shapes[i] = dist(rand_int_generator);
	}
	return OK;
}

void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	WorldChunk test_chunk = WorldChunk();
	print_line(vformat("Type: %d", p_variant.get_type()));
	// print_line(vformat("Hello! %d %d", WorldUtils::get_instance().testval, WorldUtils::get_instance().undefinedint));
	print_line(vformat("Some tile shapes: %d %d", test_chunk.tile_shapes[0], test_chunk.tile_shapes[4095]));
	print_line(vformat("Enum test: %d %d", TILE_SHAPE::FULL, TILE_SHAPE::EMPTY));
	print_line(vformat("Test chunk generation status: %d", test_chunk.generate()));
	print_line(vformat("First few tiles of test chunk: %d %d %d %d %d %d %d %d", test_chunk.tile_shapes[0], test_chunk.tile_shapes[1], test_chunk.tile_shapes[2], test_chunk.tile_shapes[3], test_chunk.tile_shapes[4], test_chunk.tile_shapes[5], test_chunk.tile_shapes[6], test_chunk.tile_shapes[7]));
}
