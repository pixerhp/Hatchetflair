#include "chunk_load_utils.hpp"

#include "gde.hpp"

#include <algorithm>
#include <cmath>
#include <utility>

// CAUTION: These are used in multithreading without mutex protection (typically they're only read from),
// take care to avoid using them during reinitializing (such as due to changing settings) via Godot thread management.
float chunk_load_utils::chunk_onload_radius_squared = 0.5 * 0.5; // (inclusive)
float chunk_load_utils::chunk_offload_radius_squared = 0.5 * 0.5; // (exclusive)
std::vector<godot::Vector3i> chunk_load_utils::chunk_onload_checks = {godot::Vector3i(0, 0, 0)}; //(ordered ascending)

void create_chunk_onload_checks() {
    // Search through a cube of chuords that circumscribes the onload-radius sphere, for chuords within that sphere:
    // (This could potentially be optimized by only checking ~1/8th of the cube via symmetries, but it doesn't matter much.)
    std::vector<godot::Vector3i> new_checks;
    int search_axis_offset = static_cast<int>(std::ceil(std::sqrt(chunk_load_utils::chunk_onload_radius_squared)));
    int search_sidelength = (search_axis_offset * 2) + 1;
    new_checks.reserve(search_sidelength * search_sidelength * search_sidelength); //(reserving for worst-case)
    for (int z = -search_axis_offset; z <= search_axis_offset; ++z) {
        for (int y = -search_axis_offset; y <= search_axis_offset; ++y) {
            for (int x = -search_axis_offset; x <= search_axis_offset; ++x) {
                if (static_cast<float>(godot::Vector3i(x, y, z).length_squared()) <= chunk_load_utils::chunk_onload_radius_squared) {
                    new_checks.push_back(godot::Vector3i(x, y, z));
                }
            }
        }
    }
    // Sort the list of chuords by their squared lengths, and save the result:
    std::sort(new_checks.begin(), new_checks.end(), [](const godot::Vector3i &a, const godot::Vector3i &b) {
        return a.length_squared() < b.length_squared();
    });
    chunk_load_utils::chunk_onload_checks = std::move(new_checks);
    chunk_load_utils::chunk_onload_checks.shrink_to_fit();
}

void GDE::initialize_chunk_load_utils(float new_chunk_onload_radius, float new_chunk_offload_radius) {
	chunk_load_utils::chunk_onload_radius_squared = new_chunk_onload_radius * new_chunk_onload_radius;
	chunk_load_utils::chunk_offload_radius_squared = new_chunk_offload_radius * new_chunk_offload_radius;
    create_chunk_onload_checks();
}
