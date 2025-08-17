extends Node

const TCHUNK_L: int = 16
const TCHUNK_T: int = TCHUNK_L ** 3
const TCHUNK_S: Vector3i = Vector3i(TCHUNK_L, TCHUNK_L, TCHUNK_L)
const TCHUNK_HL: float = TCHUNK_L / 2.0
const TCHUNK_HS: Vector3 = Vector3(TCHUNK_HL, TCHUNK_HL, TCHUNK_HL)
const TCHUNK_HS2: Vector3 = Vector3(TCHUNK_HL - 0.5, TCHUNK_HL - 0.5, TCHUNK_HL - 0.5)

const ts_tess_cube_move: Array[Vector3i] = [
	Vector3i(-1, 0, 0), Vector3i(1, 0, 0),
	Vector3i(0, -1, 0), Vector3i(0, 1, 0),
	Vector3i(0, 0, -1), Vector3i(0, 0, 1),
]
const ts_tess_cube_verts: PackedVector3Array = [
	Vector3(0, 0, 0)-TCHUNK_HS,Vector3(0, 1, 0)-TCHUNK_HS,Vector3(0, 0, 1)-TCHUNK_HS,Vector3(0, 1, 1)-TCHUNK_HS,
	Vector3(1, 0, 1)-TCHUNK_HS,Vector3(1, 1, 1)-TCHUNK_HS,Vector3(1, 0, 0)-TCHUNK_HS,Vector3(1, 1, 0)-TCHUNK_HS,
	
	Vector3(1, 0, 0)-TCHUNK_HS,Vector3(0, 0, 0)-TCHUNK_HS,Vector3(1, 0, 1)-TCHUNK_HS,Vector3(0, 0, 1)-TCHUNK_HS,
	Vector3(0, 1, 0)-TCHUNK_HS,Vector3(1, 1, 0)-TCHUNK_HS,Vector3(0, 1, 1)-TCHUNK_HS,Vector3(1, 1, 1)-TCHUNK_HS,
	
	Vector3(1, 0, 0)-TCHUNK_HS,Vector3(1, 1, 0)-TCHUNK_HS,Vector3(0, 0, 0)-TCHUNK_HS,Vector3(0, 1, 0)-TCHUNK_HS,
	Vector3(0, 0, 1)-TCHUNK_HS,Vector3(0, 1, 1)-TCHUNK_HS,Vector3(1, 0, 1)-TCHUNK_HS,Vector3(1, 1, 1)-TCHUNK_HS,
]
# (Tesselated cube doesn't have norms because we can reuse index 0-5 of 'move' as them.)

const ts_tess_rhombdo_move: Array[Vector3i] = [
	Vector3i(0, -1, -1), Vector3i(-1, 0, -1), Vector3i(1, 0, -1), Vector3i(0, 1, -1), 
	Vector3i(-1, -1, 0), Vector3i(1, -1, 0), Vector3i(-1, 1, 0), Vector3i(1, 1, 0), 
	Vector3i(0, -1, 1), Vector3i(-1, 0, 1), Vector3i(1, 0, 1), Vector3i(0, 1, 1), 
	
	Vector3i(0, -1, 0), Vector3i(0, 0, -1), Vector3i(0, 0, -1), Vector3i(-1, 0, 0), 
	Vector3i(1, 0, 0), Vector3i(0, 0, -1), Vector3i(0, 0, -1), Vector3i(0, 1, 0), 
	Vector3i(0, -1, 0), Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(1, 0, 0), 
	Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(0, 1, 0), 
	Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), 
	Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 1, 0), 
]
const ts_tess_rhombdo_verts: PackedVector3Array = [
	Vector3(0, -1, 0) - TCHUNK_HS2, Vector3(0.5, -0.5, -0.5) - TCHUNK_HS2, 
		Vector3(-0.5, -0.5, -0.5) - TCHUNK_HS2, Vector3(0, 0, -1) - TCHUNK_HS2,
	Vector3(0, 0, -1) - TCHUNK_HS2, Vector3(-0.5, 0.5, -0.5) - TCHUNK_HS2, 
		Vector3(-0.5, -0.5, -0.5) - TCHUNK_HS2, Vector3(-1, 0, 0) - TCHUNK_HS2,
	Vector3(1, 0, 0) - TCHUNK_HS2, Vector3(0.5, 0.5, -0.5) - TCHUNK_HS2, 
		Vector3(0.5, -0.5, -0.5) - TCHUNK_HS2, Vector3(0, 0, -1) - TCHUNK_HS2,
	Vector3(0, 0, -1) - TCHUNK_HS2, Vector3(0.5, 0.5, -0.5) - TCHUNK_HS2, 
		Vector3(-0.5, 0.5, -0.5) - TCHUNK_HS2, Vector3(0, 1, 0) - TCHUNK_HS2,
	
	Vector3(0, -1, 0) - TCHUNK_HS2, Vector3(-0.5, -0.5, -0.5) - TCHUNK_HS2, 
		Vector3(-0.5, -0.5, 0.5) - TCHUNK_HS2, Vector3(-1, 0, 0) - TCHUNK_HS2,
	Vector3(0, -1, 0) - TCHUNK_HS2, Vector3(0.5, -0.5, 0.5) - TCHUNK_HS2, 
		Vector3(0.5, -0.5, -0.5) - TCHUNK_HS2, Vector3(1, 0, 0) - TCHUNK_HS2,
	Vector3(-1, 0, 0) - TCHUNK_HS2, Vector3(-0.5, 0.5, -0.5) - TCHUNK_HS2, 
		Vector3(-0.5, 0.5, 0.5) - TCHUNK_HS2, Vector3(0, 1, 0) - TCHUNK_HS2,
	Vector3(1, 0, 0) - TCHUNK_HS2, Vector3(0.5, 0.5, 0.5) - TCHUNK_HS2, 
		Vector3(0.5, 0.5, -0.5) - TCHUNK_HS2, Vector3(0, 1, 0) - TCHUNK_HS2,
	
	Vector3(0, -1, 0) - TCHUNK_HS2, Vector3(-0.5, -0.5, 0.5) - TCHUNK_HS2, 
		Vector3(0.5, -0.5, 0.5) - TCHUNK_HS2, Vector3(0, 0, 1) - TCHUNK_HS2,
	Vector3(-1, 0, 0) - TCHUNK_HS2, Vector3(-0.5, 0.5, 0.5) - TCHUNK_HS2, 
		Vector3(-0.5, -0.5, 0.5) - TCHUNK_HS2, Vector3(0, 0, 1) - TCHUNK_HS2,
	Vector3(0, 0, 1) - TCHUNK_HS2, Vector3(0.5, 0.5, 0.5) - TCHUNK_HS2, 
		Vector3(0.5, -0.5, 0.5) - TCHUNK_HS2, Vector3(1, 0, 0) - TCHUNK_HS2,
	Vector3(0, 0, 1) - TCHUNK_HS2, Vector3(-0.5, 0.5, 0.5) - TCHUNK_HS2, 
		Vector3(0.5, 0.5, 0.5) - TCHUNK_HS2, Vector3(0, 1, 0) - TCHUNK_HS2,
]
const ts_tess_rhombdo_norms: PackedVector3Array = [
	0.70710678 * Vector3(ts_tess_rhombdo_move[0]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[1]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[2]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[3]),
	
	0.70710678 * Vector3(ts_tess_rhombdo_move[4]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[5]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[6]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[7]),
	
	0.70710678 * Vector3(ts_tess_rhombdo_move[8]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[9]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[10]),
	0.70710678 * Vector3(ts_tess_rhombdo_move[11]),
]

# (can use rotations of these patterns to get all of the other shapes,
# and can invert bit-states but flip vertex order and normal vectors,
# to generate every marching cube combination.)
const ts_march_pattern_states: PackedByteArray = [
	0b00000000, 0b00000001, 0b00000011, 0b00001001, 0b10000001,
	0b00000111, 0b01000011, 0b01001001, 0b00001111, 0b00010111,
	0b00100111, 0b11000011, 0b10000111, 0b01101001,
]
const ts_march_pattern_verts: PackedVector3Array = [
	# Edge midpoints:
	Vector3(0,-0.5,-0.5), Vector3(-0.5,0,-0.5), 
	Vector3(0.5,0,-0.5), Vector3(0,0.5,-0.5),
	Vector3(-0.5,-0.5,0), Vector3(0.5,-0.5,0),
	Vector3(-0.5,-0.5,0), Vector3(0.5,0.5,0),
	Vector3(0,-0.5,0.5), Vector3(-0.5,0,0.5), 
	Vector3(0.5,0,0.5), Vector3(0,0.5,0.5),
	# Face ambiguity center-points:
	Vector3(0,0,-0.5), Vector3(0,-0.5,0),
	Vector3(-0.5,0,0), Vector3(0.5,0,0),
	Vector3(0,0.5,0), Vector3(0,0,0.5),
	# Volume center-point:
	Vector3(0,0,0),
]
const ts_march_pattern_inds: Array[PackedByteArray] = [ 
	[],
	[0,1,4],
	[2,1,4, 4,5,2],
	[0,12,4, 4,12,1, 3,12,7, 7,12,2],
	[0,1,4, 11,7,10],
	
	[4,5,2, 4,2,3, 4,3,6],
	[14,2,1, 14,5,2, 14,4,5, 14,6,11, 14,11,9],
	[0,14,4, 0,12,14, 1,14,12,  7,12,2, 7,16,12, 3,12,16,  9,16,11, 9,14,16, 6,16,14],
	[5,7,6, 7,4,5],
	[2,6,8,  3,6,2, 5,2,8, 9,8,6],
	
	[2,3,10, 3,6,10, 8,10,6, 4,8,6],
	[1,14,2, 15,2,14,  7,15,6, 14,6,15,  9,14,10, 15,10,14,  5,15,4, 14,4,15],
	[4,5,15, 4,15,16, 4,16,6,  7,15,16,  2,3,16, 2,16,15,  10,11,16, 10,16,15],
	[18,13,12, 0,12,13,  18,14,13, 4,13,14,  18,13,17, 8,17,13,  18,15,13, 5,13,15,
		18,12,1, 18,1,14,  18,9,14, 18,17,9,  18,17,10, 18,10,15,  18,2,15, 18,12,2,
		18,16,12, 3,12,16,  18,14,16, 6,16,14,  18,16,17, 11,17,16,  18,15,16, 7,16,15],
]

# inneficient brute-forcing, but that's OK because it's just a dev tool.
func print_march_data_from_patterns():
	var verts_string: String = ""
	var inds_string: String = ""
	
	var patt_i: int = 0
	var rot_z: int = 0
	var rot_y: int = 0
	var rot_x: int = 0
	var flip_x: bool = false
	var inv_state: bool = false
	for comb in range(0, 256):
		for i in range(0, 4*4*4*2*2*ts_march_pattern_states.size()):
			inv_state = bool(posmod(i, 2))
			flip_x = bool(posmod(i/2, 2))
			rot_x = posmod(i/4, 4)
			rot_y = posmod(i/16, 4)
			rot_z = posmod(i/64, 4)
			patt_i = i/256
			if (transform_march_state(comb, rot_z, rot_y, rot_x, flip_x, inv_state) == 
			ts_march_pattern_states[patt_i]):
				
				pass
				
				break
	
	print(verts_string)
	print("\n\n\n\n")
	print(inds_string)
	print("\n\n\n\n")

func transform_march_state(comb, rot_z, rot_y, rot_x, flip_x, inv_state) -> int:
	for i in range(0, rot_z):
		pass
	for i in range(0, rot_y):
		pass
	for i in range(0, rot_x):
		comb = (
			(comb & 0b00110000 >> 4) | (comb & 0b00000011 << 2) | 
			(comb & 0b11000000 >> 2) | (comb & 0b00001100 << 4)
		)
	if flip_x:
		comb = ((comb & 0b10101010) >> 1) | ((comb & 0b01010101) << 1)
	if inv_state:
		comb = ~ comb
	return comb

func transform_verts(patt_i, rot_z, rot_y, rot_x, flip_x, inv_state) -> PackedVector3Array:
	
	
	return PackedVector3Array()

const ts_march_verts: PackedVector3Array = [
	
]
const ts_march_inds: PackedByteArray = [
	
]
