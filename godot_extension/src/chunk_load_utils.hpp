/*  CHUNK_LOAD_UTILS OVERVIEW
    Handles consts, cached data, and tool functions related to chunk loading.
*/

#pragma once

#include <vector>

#include "godot_cpp/variant/vector3i.hpp"

namespace chunk_load_utils {
    extern float chunk_onload_radius;
    extern float chunk_offload_radius;
    extern std::vector<godot::Vector3i> chunk_onload_check_list = {};
    // TODO function for generating
}
