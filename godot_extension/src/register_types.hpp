/*  REGISTER_TYPES OVERVIEW
    Registers classes from this GDExtension (such as GDE) with Godot during scene initialization, 
    and also handles their uninitialization.
*/

#pragma once

#include <godot_cpp/godot.hpp>

void initialize_gdextension_types(godot::ModuleInitializationLevel p_level);
void uninitialize_gdextension_types(godot::ModuleInitializationLevel p_level);
