#include "world_utils.hpp"

#include <iostream>
#include <map>
#include <vector>
#include <string>
#include "godot_cpp/variant/vector3i.hpp"

namespace world_utils {

void _toolfunc_gen_voxel_dist_shells() {
    const float SPHERE_RADIUS = 12.0; // The radius of the spherical region to generate sorted voxel coords for.
    const int SQDIST_LIMIT = static_cast<int>(std::round(SPHERE_RADIUS)) * static_cast<int>(std::round(SPHERE_RADIUS));
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
    std::multimap<int, godot::Vector3i> sorted_eigth_multimap;
    { int new_sqdist;
    for (int i = 0; i < (EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN * EIGHTH_CUBE_LEN); i++) {
        new_sqdist = (raw_vec3is[i].x * raw_vec3is[i].x) + (raw_vec3is[i].y * raw_vec3is[i].y) + (raw_vec3is[i].z * raw_vec3is[i].z);
        if (new_sqdist > SQDIST_LIMIT) {continue;}
        sorted_eigth_multimap.insert(std::pair<int, godot::Vector3i>(new_sqdist, raw_vec3is[i]));
    } }

    // Expand the ordered eighth-list of coords to to its full size, also sorted into shells:
    std::vector<std::vector<godot::Vector3i>> final_shells = {};
    {   int last_sqdist = -1; 
        int shell_index = -1; 
        std::vector<godot::Vector3i> symmetrized = {};
        int symm_temp_size = 0;
        const godot::Vector3i sym_multipliers[3] = {godot::Vector3i(-1,1,1), godot::Vector3i(1,-1,1), godot::Vector3i(1,1,-1)};
        for (auto const& [sqdist, vect3i] : sorted_eigth_multimap) {
            // Converts the Vector3i into a series of 3 chars, and then conditionally spreads it out using cube symmetries:
            symmetrized.clear();
            symmetrized = {vect3i};
            for (int axis = 0; axis < 3; axis++) {
                if (vect3i[axis] != 0) { 
                    symm_temp_size = symmetrized.size();
                    for (int i = 0; i < symm_temp_size; i++) {
                        symmetrized.push_back(symmetrized[i] * sym_multipliers[axis]);
                    } 
                } 
            }
            // Append to final shells vector:
            if (sqdist > last_sqdist) {
                shell_index++;
                final_shells.push_back({});
            }
            for (int i = 0; i < symmetrized.size(); i++) {
                final_shells[shell_index].push_back(symmetrized[i]);
            } 
    } }

    // Format and print out the results:
    std::string out_string = "";
    for (int shell_i = 0; shell_i < final_shells.size(); shell_i++) {
        out_string += "{";
        for (int i = 0; i < final_shells[shell_i].size(); i++) {
            out_string += (
                "godot::Vector3i(" + 
                std::to_string(final_shells[shell_i][i].x) + "," + 
                std::to_string(final_shells[shell_i][i].x) + "," + 
                std::to_string(final_shells[shell_i][i].x) + "), "
            );
        }
        out_string.resize(out_string.size() - 2);
        out_string += "}\n";
    }
    out_string.resize(out_string.size() - 1);
    godot::print_line(out_string.c_str());
}

}