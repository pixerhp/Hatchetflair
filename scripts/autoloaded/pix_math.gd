# A collection of custom math-related functions.

extends Node


# prob represents a (usually random) number between 0 (inclusive) and 1 (exclusive).
	# prob input < 0 is ok, and appropriately gives negative outputs. 
	# prob input >= 1 is NOT ok, ==1 would result in infinity and > 1 would result in a complex num.
# a rate of r means that an output of n is r times rarer than an output of n-1.
	# ((rate - 1) / rate) is the probability that given a random input, the output will lie between 0 and 1.
# a rate of e (2.71828...) may be considered a "natural" raritier.
func prob_to_raritier(rate: float, prob: float) -> float:
	if (rate <= 0) or (rate == 1):
		push_error("Bad rate input (is <= 0 or is == 1) of: ", rate, " (returning 0.)")
		return 0
	if prob >= 1:
		push_error("Bad prob input (is >= 1) of: ", prob, " (returning 0.)")
		return 0
	return -1 * (log(1 - prob) / log(rate))
func rand_raritier(rate: float) -> float:
	var rng_float: float = randf()
	while rng_float == 1: #(1 is a possible ranf() value, which is a bad raritier prob input.)
		rng_float = randf()
	return prob_to_raritier(rate, rng_float)

func raritier_to_prob(rate: float, val: float) -> float:
	if (rate <= 0):
		push_error("Bad rate input (is <= 0) of: ", rate, " (returning 0.)")
		return 0
	if (rate == 1): # This is a mathematically valid (albeit weird) input for this particular function.
		return 0
	return 1 - pow(rate, -1 * val)

# Combine raritier values.
	# Ex. with a rate of 3, combining 3 of the same value n together outputs n + 1.
	# It's not however limited to nice numbers/combinations though, fractional inputs/outputs are possible.
func raritier_combine(rate: float, values: Array[float]) -> float:
	if (rate <= 0) or (rate == 1):
		push_error("Bad rate input (is <= 0 or is == 1) of: ", rate, " (returning 0.)")
		return 0
	if values.size() < 1:
		push_error("No input raritier values. (returning 0.)")
		return 0
	var combined: float = 0 
	for val in values:
		combined += pow(rate, val) # Expected precision-loss or even error with high rate and/or raritier values.
	return log(combined)/log(rate)

# Combine raritier values that have independant associated rates.
func raritier_combine_adv(outrate: float, rates: Array[float], values: Array[float]) -> float:
	if values.size() < 1:
		push_error("No input raritier values. (returning 0.)")
		return 0
	if rates.size() != values.size():
		push_error("Rates and values inputs are not the same size. (returning 0.)")
		return 0
	var combined: float = 0 
	for i in values.size():
		if (rates[i] <= 0) or (rates[i] == 1):
			push_error("At least 1 bad associated rate (is <= 0 or is == 1) of: ", rates[i], " (returning 0.)")
			return 0
		combined += pow(rates[i], values[i]) # Expected precision-loss or even error with high rate and/or raritier values.
	return log(combined)/log(outrate)
