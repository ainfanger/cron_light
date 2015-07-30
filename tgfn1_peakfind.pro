; TGFN1_PEAKFIND:
; Looks through 4s worth of data and identifies any peaks. Adds them to structure array and temp file.
; - minute (IN): The minute of data we're currently in.
; - timescale_index (IN): The index for array "cfg_timescales" to use. Determines binsize.
; - eventlist (IN): List of event times (in seconds) from eventlist object.
; - detectorlist (IN): Corresponding detectors
; - offset (IN): Optional offset to histogram, by half of binsize.



pro tgfn1_peakfind, minute, timescale_index, eventlist, detectorlist, offset = offset


; Load config file and restore common blcoks
	@tgfn_config
	common triggers, trigger_structures
	common poisson, poissontable

	IF n_elements(eventlist) le 1 THEN return

	hist_binsize = cfg_timescales[timescale_index]*0.001d
	IF n_elements(offset) eq 0 THEN hoffset = 0.0 ELSE hoffset = hist_binsize*0.5
	max_prob = cfg1_max_probabilities[timescale_index]

; Create histogram.
	hist = histogram(eventlist, min = min(eventlist) - hoffset, binsize = hist_binsize, locations = event_times)
	ave = average(hist)
	IF ave gt 500 THEN return

; To avoid unreasonable differences in averages (i.e. saa) when peakfind is called several
; times, split histogram in two to get two averages and force second
; average to be within 20% of first average. 
	split_ave1 = average(hist[0:n_elements(hist)/2])
	split_ave2 = average(hist[n_elements(hist)/2:n_elements(hist)-1])
	IF split_ave2 LE 0.80*split_ave1 OR split_ave2 GE 1.20*split_ave1 THEN return

; Determine Poisson probabilities from lookup table. poissontable is indexed by:
;   [<250*bkg>, <# counts>]
	ave_index = max([round(250*ave), 1])
	probabilities = poissontable[ave_index, hist]
	peaks = where(probabilities lt max_prob AND hist gt ave, num_peaks)

; Cycle through any items with a small probability.
	FOR i = 0L, num_peaks-1 DO BEGIN


; Determine the time of the TGF. Check that there are a realistic number of counts within +- 0.5s.
		event_time = event_times[peaks[i]] + hist_binsize*0.5
		IF event_time lt minute THEN continue
		nearby = where(eventlist gt event_time-0.5d AND eventlist lt event_time+0.5d, n)
		IF (n le 3 OR n ge 18000) THEN continue


; THIS IS WHERE WE CHECK WHETHER THERE ARE MANY COUNTS FROM ONE DETECTOR ALL IN A SHORT INTERVAL          
; Pick out events really in (or near) the burst, and the dets associated with them:
		burst = where(eventlist gt event_time - hist_binsize AND eventlist le event_time + hist_binsize, in_burst)
		detectors = detectorlist[burst]
		 
; Step through each detector in turn and see if it makes up > 1/3 of the counts. If it did, continue.
		good = 1
		FOR j = 0, 8 DO BEGIN
			IF good eq 0 THEN continue
			with = where(detectors eq j + 9, nwith)
			IF (1.*nwith)/(1.*in_burst) gt 0.333 THEN good = 0
		ENDFOR
		IF good eq 0 THEN continue


; Add to the structure of triggers
		new_evt = {stage1_struct}
		new_evt.timestamp = anytim(event_time, /ccsds)
		new_evt.timescale = timescale_index
		trigger_structures = [trigger_structures, new_evt]

; Print out the event and its timestamp
		tgfn_log, 1, 'NEW EVENT: ' + new_evt.timestamp + ' (' + num2str(cfg_timescales[new_evt.timescale], format='(f5.2)') + 'ms)'

	ENDFOR

end
