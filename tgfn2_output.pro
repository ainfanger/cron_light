pro tgfn2_output, event_time, ts, elist, tlow, thigh, filename, timescale_index, halvesdiff,  burst_rate, subevent_rate, num_counts, burst_duration, conc, probability, n_uld_events


; Load config
	@tgfn_config

; Open file up for writing if it doesn't exist.
	IF file_test(filename + '.txt') eq 1 THEN return


; Grab latitude & longitude
	latlon1 = hsi_get_latlon(event_time)
	latlon2 = hsi_get_latlon(event_time, /sattrack)
	if latlon1[2] LT 0. then latlon = latlon2
	if latlon2[2] LT 0. then latlon = latlon1


; DETERMINE TGF DURATIONS

; Define intervals near (within +/- 2ms) and far (> 50ms away) to integrate the TGF counts and define the background:
	near = where(abs(ts-tlow) LT 2.,nn)
	IF nn eq 0 THEN return
	far = where(abs(ts-tlow) GT 50.,nf)
	bkg = (nf*1.d)/(max(ts)-min(ts)-100.d) 

; Iterate through each percent. Start with 50% and continue if we get a negative bkg...
	sub = (nn*1.d) - (bkg*4.d) ;remember we're using a 4ms wide bin to calc. near
		
; Subtract background and get "frac" = 50% of the counts in the TGF above bkg:
	frac = floor(0.5*sub)
		
; The duration of the TGF is the shortest interval containing "frac" counts:
	tdiff = ts[near+frac]-ts[near]
	dur = min(tdiff)
		
; Now iterate correcting for the expected amount of bkg in "frac". Ideally you'd integrate until you converge, but this is probably
; fine. It only matters for the longer ones:
	frac2 = floor(0.5*sub + bkg*dur)
	tdiff2 = ts[near+frac2]-ts[near]
	dur50 = min(tdiff2)

; 68.27%
	frac = floor(0.6827*sub)
	tdiff = ts[near+frac]-ts[near]
	dur = min(tdiff)
	frac2 = floor(0.6827*sub + bkg*dur)
	tdiff2 = ts[near+frac2]-ts[near]
	dur68 = min(tdiff2)	

; 90%	
	frac = floor(0.9*sub)
	tdiff = ts[near+frac]-ts[near]
	dur = min(tdiff)
	frac2 = floor(0.9*sub + bkg*dur)
	tdiff2 = ts[near+frac2]-ts[near]
	dur90 = min(tdiff2)	








; Repeat for elist >= 500 keV
	t_high_energy = elist[where(elist ge 500)]

	near_he = where(abs(t_high_energy-tlow) LT 2.,nn)
	far_he = where(abs(t_high_energy-tlow) GT 50.,nf)
	IF nn ne 0 THEN BEGIN

		
		bkg = (nf*1.d)/(max(t_high_energy)-min(t_high_energy)-100.d) 
		sub_he = (nn*1.d) - (bkg*4.d)
		
		
	; 50%
		frac = floor(0.5*sub_he)
		tdiff = t_high_energy[near_he+frac]-t_high_energy[near_he]
		dur = min(tdiff)	
		frac2 = floor(0.5*sub_he + bkg*dur)
		tdiff2 = t_high_energy[near_he+frac2]-t_high_energy[near_he]
		dur50_he = min(tdiff2)

	; 68.27%
		frac = floor(0.6827*sub_he)
		tdiff = t_high_energy[near_he+frac]-t_high_energy[near_he]
		dur = min(tdiff)
		frac2 = floor(0.6827*sub_he + bkg*dur)
		tdiff2 = t_high_energy[near_he+frac2]-t_high_energy[near_he]
		dur68_he = min(tdiff2)	

	; 90%	
		frac = floor(0.9*sub_he)
		tdiff = t_high_energy[near_he+frac]-t_high_energy[near_he]
		dur = min(tdiff)
		frac2 = floor(0.9*sub_he + bkg*dur)
		tdiff2 = t_high_energy[near_he+frac2]-t_high_energy[near_he]
		dur90_he = min(tdiff2)	
		


	ENDIF ELSE BEGIN
		dur50_he = -1
		dur68_he = -1
		dur90_he = -1
		sub_he = -1
	ENDELSE



	; Make sure each is positive
	IF dur50 le 0 THEN dur50 = -1
	IF dur68 le 0 THEN dur68 = -1
	IF dur90 le 0 THEN dur90 = -1
	IF dur50_he le 0 THEN dur50_he = -1
	IF dur68_he le 0 THEN dur68_he = -1
	IF dur90_he le 0 THEN dur90_he = -1
	IF sub le 0 THEN sub = -1
	IF sub_he le 0 THEN sub_he = -1




; Print out the basic information to the file
	openw, lun, filename + '.txt', /get_lun
	printf, lun, (timescale_index + 1)	; Line 0: Triggering timescale from Stage 1. The website expects it to be one higher than it is...
	printf, lun, event_time, format='(D0)'	; Line 1: Event timestamp (This is _not_ UNIX!)
	printf, lun, latlon[0]			; Line 2: Latitude
	printf, lun, latlon[1]			; Line 3: Longitude
	printf, lun, halvesdiff			; Line 4: Halvesdiff
	printf, lun, burst_rate			; Line 5: Burst Rate
	printf, lun, subevent_rate		; Line 6: Background Rate
	printf, lun, num_counts			; Line 7: # Counts (Cleaned)
	printf, lun, burst_duration		; Line 8: Burst duration
	printf, lun, conc			; Line 9: Concentration of events in detectors
	printf, lun, probability		; Line 10: Poisson probability of peak
	printf, lun, n_uld_events		; Line 11: Percent of events that are ULD.
	printf, lun, dur50			; Line 12: T_50
	printf, lun, dur50_he			; Line 13: T_50, for energy >= 500keV
	printf, lun, dur68			; Line 14: T_68
	printf, lun, dur68_he			; Line 15: T_68, for energy >= 500keV
	printf, lun, dur90			; Line 16: T_90
	printf, lun, dur90_he			; Line 17: T_90, for energy >= 500keV
	printf, lun, sub			; Line 18: Background-subtracted counts in burst
	printf, lun, sub_he			; Line 19: Background-subtracted counts >= 500keV in burst
	free_lun, lun


; CREATE TEXT HISTOGRAM 

; Determine binsize. Bin large timescales more finely. Pick the lowest bin so it lines up with the start of the peak.
	timescale_index = min([timescale_index, 4])
	hist_binsize = cfg_timescales[timescale_index]*0.25
	min_bin = tlow MOD hist_binsize

; Create another histogram of events
	h = histogram(ts, binsize=hist_binsize, min=min_bin, locations=x)

; in_pk is "1" in what Stage 2 considered "the peak".	
	in_pk = bytarr(n_elements(h))
	peak = where(x ge tlow AND x lt thigh, nt)
	IF nt ne 0 THEN in_pk[peak] = 1

; Create a text file and output this nonsense. Output 'adjacent' neighbors for comparison
	openw, new_unit, filename + '.hist', /get_lun
	FOR i = max([min(peak) - cfg2_adjacent_bins, 0]), min([max(peak) + cfg2_adjacent_bins, n_elements(h)-1]) DO printf, new_unit, x[i], h[i], in_pk[i]
	free_lun, new_unit



end
