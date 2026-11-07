#include "world_data.hpp"

#include "gde.hpp"

#include <godot_cpp/variant/array.hpp>

template class ConcurrentMap<godot::Vector3i, WorldChunk>;

WorldChunksMap world_chunks_map;

godot::Array GDE::get_chunk_lengths() {
	godot::Array chunk_lengths;
	chunk_lengths.append(DATA_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_CHUNK_LEN);
	chunk_lengths.append(TERRAIN_MESH_SUBCHUNK_LEN);
	return chunk_lengths;
}
