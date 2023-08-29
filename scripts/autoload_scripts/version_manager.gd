extends Node
# NOTE: cv stands for "correct version". It is also sometimes used to mean "correct version of/for".


# Returns true if one or more essential files failed to be (or be transversioned to) the correct version.
func ensure_cv_essential_files() -> bool: 
	return false # return false if by the end of this function all essential files are the correct version.
