#include "world_data.hpp"

#include "gde.hpp"

#include <godot_cpp/variant/array.hpp>

std::map<godot::Vector3i, WorldChunk> world_chunks_map;
std::mutex world_chunks_map_mutex;

godot::Array GDE::get_chunk_lengths() {
	godot::Array chunk_lengths;
	chunk_lengths.append(DATA_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_SUBCHUNK_LEN);
	return chunk_lengths;
}
