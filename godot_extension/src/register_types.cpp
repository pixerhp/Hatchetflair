#include "register_types.hpp"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/godot.hpp>

#include "gde.hpp"

using namespace godot;

GDE *gde_singleton = nullptr;

void initialize_gdextension_types(ModuleInitializationLevel p_level)
{
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	/* NOTE using GDREGISTER_INTERNAL_CLASS instead would prevent being able to instance multiple GDE in Godot,
	but would also require accessing it via Engine.get_singleton("GDE") or with some created wrapper. (I think)*/
	GDREGISTER_CLASS(GDE); 
	gde_singleton = memnew(GDE);
	Engine::get_singleton()->register_singleton("GDE", gde_singleton);
	
}

void uninitialize_gdextension_types(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	Engine::get_singleton()->unregister_singleton("GDE");
	memdelete(gde_singleton);
	gde_singleton = nullptr;
}

extern "C"
{
	// Initialization
	GDExtensionBool GDE_EXPORT hatchetflair_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization)
	{
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_gdextension_types);
		init_obj.register_terminator(uninitialize_gdextension_types);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

		return init_obj.init();
	}
}
