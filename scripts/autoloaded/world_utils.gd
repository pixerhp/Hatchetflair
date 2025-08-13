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

const ts_angular_march_pattern_states: PackedByteArray = [
	0b00000000,
]

const ts_angular_march_pattern_verts: PackedVector3Array = [
	
]

const ts_angular_march_combinations_verts: PackedVector3Array = [
	
]
