#include "chunk_mesh_utils.hpp"

// !!! Everything after this is not yet reviewed, review/revise all next session:

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>
#include <godot_cpp/variant/transform3d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/vector3.hpp>

namespace chunk_mesh_utils {

bool create_test_mesh(godot::RenderingServer *rendering_server, godot::Vector3i chuord, WorldChunk &world_chunk) {
	if (rendering_server == nullptr) {
		godot::UtilityFunctions::push_error("RenderingServer is not initialized; cannot create chunk test mesh.");
		return false;
	}
	const godot::RID &scenario = get_chunks_render_scenario();
	if (!scenario.is_valid()) {
		godot::UtilityFunctions::push_error("Chunk render scenario is not set; cannot create chunk test mesh.");
		return false;
	}

	godot::PackedVector3Array vertices;
	const godot::real_t half = 0.5;
	vertices.append(godot::Vector3(-half, -half, -half));
	vertices.append(godot::Vector3(half, -half, -half));
	vertices.append(godot::Vector3(half, half, -half));
	vertices.append(godot::Vector3(-half, half, -half));
	vertices.append(godot::Vector3(-half, -half, half));
	vertices.append(godot::Vector3(half, -half, half));
	vertices.append(godot::Vector3(half, half, half));
	vertices.append(godot::Vector3(-half, half, half));

	godot::PackedInt32Array indices;
	const int32_t cube_indices[] = {
		0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7,
		0, 4, 7, 0, 7, 3, 1, 2, 6, 1, 6, 5,
		0, 1, 5, 0, 5, 4, 3, 7, 6, 3, 6, 2
	};
	for (int32_t index : cube_indices) {
		indices.append(index);
	}

	godot::Array surface_arrays;
	surface_arrays.resize(godot::RenderingServer::ARRAY_MAX);
	surface_arrays[godot::RenderingServer::ARRAY_VERTEX] = vertices;
	surface_arrays[godot::RenderingServer::ARRAY_INDEX] = indices;

	world_chunk.test_mesh = rendering_server->mesh_create();
	if (!world_chunk.test_mesh.is_valid()) {
		godot::UtilityFunctions::push_error("Failed to create chunk test mesh.");
		return false;
	}
	rendering_server->mesh_add_surface_from_arrays(world_chunk.test_mesh, godot::RenderingServer::PRIMITIVE_TRIANGLES, surface_arrays);
	world_chunk.test_mesh_instance = rendering_server->instance_create2(world_chunk.test_mesh, scenario);
	if (!world_chunk.test_mesh_instance.is_valid()) {
		rendering_server->free_rid(world_chunk.test_mesh);
		world_chunk.test_mesh = godot::RID();
		godot::UtilityFunctions::push_error("Failed to create chunk test mesh instance.");
		return false;
	}

	godot::Transform3D mesh_transform;
	mesh_transform.origin = godot::Vector3(
			static_cast<godot::real_t>(chuord.x) * WORLD_CHUNK_LEN,
			static_cast<godot::real_t>(chuord.y) * WORLD_CHUNK_LEN,
			static_cast<godot::real_t>(chuord.z) * WORLD_CHUNK_LEN);
	rendering_server->instance_set_transform(world_chunk.test_mesh_instance, mesh_transform);
	return true;
}

bool free_test_mesh(godot::RenderingServer *rendering_server, const WorldChunk &world_chunk) {
	if (rendering_server == nullptr) {
		godot::UtilityFunctions::push_error("RenderingServer is not initialized; cannot free chunk test mesh.");
		return false;
	}
	if (world_chunk.test_mesh_instance.is_valid()) {
		rendering_server->free_rid(world_chunk.test_mesh_instance);
	}
	if (world_chunk.test_mesh.is_valid()) {
		rendering_server->free_rid(world_chunk.test_mesh);
	}
	return true;
}

}
