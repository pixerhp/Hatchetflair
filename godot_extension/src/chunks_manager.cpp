#include "chunks_manager.h"
#include "world_utils.h"

void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	WorldChunk test_chunk = WorldChunk();
	print_line(vformat("Type: %d", p_variant.get_type()));
	// print_line(vformat("Hello! %d %d", WorldUtils::get_instance().testval, WorldUtils::get_instance().undefinedint));
	print_line(vformat("Some tile shapes: %d %d", test_chunk.tile_shapes[0], test_chunk.tile_shapes[4095]));
	print_line(vformat("Enum test: %d %d", TILE_SHAPE::FULL, TILE_SHAPE::EMPTY));
}
