; TGFN2_EVALUATE()
; Applies weak thresholds to determine whether or not an event should be passed through Stage 2 to the website.
; The return value specifies whether an event passed (1) or which check it failed.
; - timescale_index (IN): The 0-based index of cfg_timescales for the event
; - num_counts (IN)
; - burst_rate (IN)
; - probability (IN)
;

function tgfn2_evaluate, timescale_index, num_counts, burst_rate, probability

	; Load config file
	@tgfn_config

	; Compare each part to the thresholds set in the config file.
	IF cfg2_min_counts[timescale_index] gt num_counts THEN return, -8
	IF cfg2_min_burst_rate[timescale_index] gt burst_rate THEN return, -9
	IF cfg2_max_probability[timescale_index] lt probability THEN return, -10

	return, 1

end
