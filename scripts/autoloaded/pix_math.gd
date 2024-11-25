# A collection of custom math-related functions.

extends Node


# prob represents a (usually random) number between 0 (inclusive) and 1 (exclusive).
	# prob input < 0 is ok, and appropriately gives negative outputs. 
	# prob input >= 1 is NOT ok, ==1 would result in infinity and > 1 would result in a complex num.
# a rate of r means that an output of n is r times rarer than an output of n-1.
	# ((rate - 1) / rate) is the probability that given a random input, the output will lie between 0 and 1.
# a rate of e (2.71828...) may be considered a "natural" raritier.
func prob_to_raritier(rate: float, prob: float) -> float:
	if prob < 1:
		return -1 * (log(1 - prob) / log(rate))
	else:
		push_error("Inappropriate prob value (is >= 1) of: ", prob, " (outputting 0.)")
		return 0
func rand_raritier(rate: float) -> float:
	var rng_float: float = randf()
	while rng_float == 1: #(1 is a possible ranf() value, which is a bad raritier prob input.)
		rng_float = randf()
	return prob_to_raritier(rate, rng_float)

# Combine raritier values.
	# Ex. with a rate of 3, combining 3 of the same value n together outputs n + 1.
	# It's not however limited to nice numbers/combinations though, fractional inputs/outputs are possible.
func raritier_combine(rate: float, values: Array[float]) -> float:
	if values.size() < 1:
		push_error("No input raritier values. (outputting 0.)")
		return 0
	var combined: float = 0 
	for val in values:
		combined += pow(rate, val) # Expected precision-loss or even error with high raritier values.
	return log(combined)/log(rate)

# Combine raritier values that have independant associated rates.
func raritier_combine_adv(outrate: float, rates: Array[float], values: Array[float]) -> float:
	if values.size() < 1:
		push_error("No input raritier values. (outputting 0.)")
		return 0
	if rates.size() != values.size():
		push_error("Rates and values inputs are not the same size. (outputting 0.)")
		return 0
	var combined: float = 0 
	for i in values.size():
		combined += pow(rates[i], values[i]) # Expected precision-loss or even error with high raritier values.
	return log(combined)/log(outrate)
