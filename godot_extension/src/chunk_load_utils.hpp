/*  CHUNK_LOAD_UTILS OVERVIEW
    Handles consts, cached data, and tool functions related to chunk loading.
*/

#pragma once

#include <vector>

#include "godot_cpp/variant/vector3i.hpp"

namespace chunk_load_utils {
    extern float chunk_onload_radius_squared;
    extern float chunk_offload_radius_squared;
    extern std::vector<godot::Vector3i> chunk_onload_checks;
}
