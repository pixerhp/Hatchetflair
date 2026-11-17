/*  CHUNK_MESH_UTILS OVERVIEW
    Provides various chunk meshing utility. [abcd]
*/

#pragma once

// !!! Everything after this is not yet reviewed, review/revise all next session:

#include "world_data.hpp"

#include <godot_cpp/classes/rendering_server.hpp>
#include <godot_cpp/variant/vector3i.hpp>

namespace chunk_mesh_utils {

bool create_test_mesh(godot::RenderingServer *rendering_server, godot::Vector3i chuord, WorldChunk &world_chunk);
bool free_test_mesh(godot::RenderingServer *rendering_server, const WorldChunk &world_chunk);

}
