extends Node
# NOTE: cv stands for "correct/current version". It is also sometimes used to mean "correct/current version of/for".


# Compares whether the input version_entire comes before (-1), is the same as (0) or probably comes after (1) the cv.
func compare_v_to_cv(in_v_entire: String) -> int:
	if in_v_entire == "":
		push_warning()
		return(127)
	# If the input version is obviously the same as the current one then we don't need to do any special comparing.
	if in_v_entire == GlobalStuff.game_version_entire:
		return(0)
	
	var in_v_components: Array[String] = GlobalStuff.unconcat_ver_entire(in_v_entire)
	
	if (in_v_components[0] != "pre-game"):
		# NOTE: in the future (specifically when the phase changes for the first time,)
		# phase comparisons will need to be manually defined here.
		return(1)
	else:
		# If the phases are equal, compare the engine versions.
		if (int(in_v_components[1]) < int(GlobalStuff.game_version_engine)):
			return(-1)
		elif (int(in_v_components[1]) > int(GlobalStuff.game_version_engine)):
			return(1)
		else:
			# If the engine versions are equal, compare the major versions.
			if (int(in_v_components[2]) < int(GlobalStuff.game_version_major)):
				return(-1)
			elif (int(in_v_components[2]) > int(GlobalStuff.game_version_major)):
				return(1)
			else:
				# If the major versions are equal, compare the minor versions.
				if (int(in_v_components[3]) < int(GlobalStuff.game_version_minor)):
					return(-1)
				elif (int(in_v_components[3]) > int(GlobalStuff.game_version_minor)):
					return(1)
	
	# Reaching here is unintended function behavior and thus should return an error.
	push_error("When comparing version \"", in_v_entire, "\" to the current ver., none of the return statements triggered.")
	return(127)


# Returns true only if one or more essential files failed to be (or be transversioned to) the correct version.
func ensure_cv_essential_files() -> bool: 
	return false # return false if by the end of this function all essential files are the correct version.
