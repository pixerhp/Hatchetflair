#include "world_utils.hpp"
#include <map>
#include <vector>
#include "godot_cpp/variant/vector3i.hpp"

using namespace world_utils;

void _toolfunc_gen_voxel_dist_shells() {
    const float SPHERE_RADIUS = 12.0; // The radius of the spherical region to generate sorted voxel coords for.
    const int SQDIST_LIMIT = static_cast<int>(std::round(SPHERE_RADIUS * 2.0));
    const int EIGHTH_CUBE_LEN = static_cast<int>(std::ceil(SPHERE_RADIUS)) + 1;

    // Initialize the unsorted list of voxel coords: (Only ~1/8 of the cube thanks to symmetries.)
    godot::Vector3i raw_vec3is[EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN];
    { int i = 0;
    for (int z = 0; z < EIGHTH_CUBE_LEN; z++) {
    for (int y = 0; y < EIGHTH_CUBE_LEN; y++) {
    for (int x = 0; x < EIGHTH_CUBE_LEN; x++) {
        raw_vec3is[i] = godot::Vector3i(x, y, z);
        i++;
    } } } }

    // Ignore OOB coords, and add relavent ones to sorted map:
    std::map<int, godot::Vector3i> sorted_eigth_map;
    { int new_sqdist;
    for (int i = 0; i < (EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN); i++) {
        new_sqdist = (raw_vec3is[i].x * raw_vec3is[i].x) + (raw_vec3is[i].y * raw_vec3is[i].y) + (raw_vec3is[i].z * raw_vec3is[i].z);
        if (new_sqdist > SQDIST_LIMIT) {continue;}
        sorted_eigth_map.insert({new_sqdist, raw_vec3is[i]});
    } }

    // !!! involve symmetries to expand into full list
}