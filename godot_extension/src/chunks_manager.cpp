#include "chunks_manager.h"
#include "world_utils.h"

void ExampleClass::_bind_methods() {
	godot::ClassDB::bind_method(D_METHOD("print_type", "variant"), &ExampleClass::print_type);
}

void ExampleClass::print_type(const Variant &p_variant) const {
	print_line(vformat("Type: %d", p_variant.get_type()));
	print_line(vformat("Hello! %d %d", WorldUtils::get_instance().testval, WorldUtils::get_instance().undefinedint));
}