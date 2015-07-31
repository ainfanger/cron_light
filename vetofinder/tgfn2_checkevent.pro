; TGFN2_CHECKEVENT
; - timestamp (IN): An anytim()-friendly timestamp (eg, YYYY-MM-DDTHH:MM:SS.ZZZ) of the candidate TGF
; - timescale_index (IN): The 0-based index for the timescale, as found in cfg_timescales.
; - return_val (OUT): A reference for whether or not an event passed. Returned to tgfn2_run to update the trigger list file.

pro tgfn2_checkevent, timestamp, timescale_index, return_val


; Include config file, restore common blocks
	@tgfn_config
	common objects, o, ob
	common poisson, poissontable_fine, poissontable_loose
	common environment, output_directory

; Establish timestamp and filename. Return if file already exists.
	event_time = anytim(timestamp)
	filename = output_directory + strjoin(strsplit(anytim(event_time, /ccsds), ':', /extract), '') + '_' + num2str(timescale_index)
	IF file_test(filename + '.txt') eq 1 THEN return


; Load event data. Only grabbing data from rear detectors!
	subevent = o->getdata(obs_time_interval = [event_time - cfg2_datawindow, event_time + cfg2_datawindow], $
		time_unit = 1, time_range = [0,0], $
		a2d_index_mask = cfg_a2d_index_mask)

; Check two ways to see if we got no data (check if subevent0 is structure)
	IF size(subevent, /type) ne 8 THEN BEGIN
		return_val = -1
		return
	ENDIF 
	IF n_tags(subevent) eq 0 THEN BEGIN
		return_val = -1
		return
	ENDIF

; Check for bad data gathering at a data gap:
	IF min(subevent.time) LT 0 THEN BEGIN
		return_val = -1
		return
	ENDIF

	s = o -> get()
	ut_ref = s.ut_ref

; Load in an extra 30s of summary data, and check for attenuator motion.
	obssum = ob->getdata(obs_time_interval=[event_time - 12.0d, event_time + 12.0d])
	obstr = ob->get()
	IF total(obssum.flags[9]) GT 0 THEN BEGIN
		return_val = -2
		return
	ENDIF

	subevent = subevent[where(subevent.channel GT -2)]


; Create a list of true energies:
	kev_energy = findgen(n_elements(subevent))
	params = hsi_get_e_edges(gain_time_wanted = string(anytim(event_time, /atime)), /coeff_only)
	fuld = where(subevent.channel EQ -1 and subevent.a2d_index LT 9, nfuld)
	ruld = where(subevent.channel EQ -1 and subevent.a2d_index GE 9, nruld)
	kev_energy = subevent.channel * params[subevent.a2d_index, 1] + params[subevent.a2d_index, 0]
	if nfuld GT 0 then kev_energy[fuld] = 3000.
	if nruld GT 0 then kev_energy[ruld] = 20000.

; Properly eliminate coincidences in the eventlist and sum up coinc
; energies. We have not yet included the appropriate time delay
; between ULDs and normal counts from the same kind of segment.
	cleanelist_fast, subevent, kev_energy, elist0, tlist0, slist0, used

; Eliminate really low-energy events (below 15)
	notlow = where(elist0 GE 15.0)
	elist = elist0[notlow]
	tlist = tlist0[notlow]
	slist = slist0[notlow]

; Create actual times
	alltimes = subevent.time / 1024.d ^2.d * 1000.d - (event_time - cfg2_datawindow - ut_ref)*1000.		;true millisec
	ts = tlist / 1024.d ^2.d * 1000.d - (event_time - cfg2_datawindow - ut_ref)*1000.			;(cleaned) true millisec


; Determine background, and compare front and back half of eventlist. Have we triggered on an edge?
	n_ts = n_elements(ts)
	w1 = where(ts LT 0.8*average(ts),nw1)
	w2 = where(ts GT 1.2*average(ts),nw2)
	if nw1 LT 1 or nw2 LT 1 THEN return
	halvesdiff = abs(nw1-nw2)/((nw1+nw2)/2.)
	subevent_duration = max(ts)-min(ts)
	subevent_rate = float(n_elements(ts))/subevent_duration 
	IF subevent_rate gt 50 THEN BEGIN
		return_val = -3
		return
	ENDIF

; Find the maximum number of counts that can fit into a bin of size hist_binsize. That's what we'll call the peak's center.
	hist_binsize = cfg_timescales[timescale_index]/4.
	FOR shift_n = 0L, n_ts/2 DO BEGIN
		IF min(ts[shift_n:*] - ts[0:n_ts-shift_n-1]) le hist_binsize THEN max_shift = shift_n ELSE break		
	ENDFOR
	subtracted = ts[max_shift:*] - ts[0:n_ts-1-max_shift]
	min_v = min(subtracted, ind)
	min_bin = (ts[ind] MOD hist_binsize) - hist_binsize
	IF min_bin gt max(ts) THEN BEGIN
		return_val = -4
		return
	ENDIF
	h = histogram(ts, binsize=hist_binsize, min=min_bin)
	hmax = max(h, hind)

; Tack on adjacent bins that are at least 1.5*background:
	bg = subevent_rate*hist_binsize*1.5
	peak_low = hind
	peak_high = hind
	FOR i = hind-1, 0, -1 DO BEGIN
		IF h[i] ge bg THEN peak_low = i ELSE break
	ENDFOR
	FOR i = hind+1, n_elements(h)-1 DO BEGIN
		IF h[i] ge bg THEN peak_high = i ELSE break
	ENDFOR
	tlow = peak_low * hist_binsize + min_bin
	thigh = (peak_high+1) * hist_binsize + min_bin


; Determine properties of the burst
	in_tgf = where(ts GE tlow and ts LE thigh, num_counts)
	;intgfraw = where(alltimes GE tlow and alltimes LE thigh, longestrun)
	;burstraws = subevent[intgfraw]
	burst_ts = ts[in_tgf]
	burst_es = elist[in_tgf]
	burst_ss = slist[in_tgf]
	burst_duration = thigh - tlow ;  milliseconds
	burst_rate = float(num_counts)/burst_duration
		
	wh_uld_events = where(burst_es ge 20000, n_uld_events)
	n_uld_events = round(100*n_uld_events / num_counts)

; Search for solar flares; are a lot of the counts below 30 keV?
; Are a lot of the counts in the front segments? (WE'RE NOT USING FRONTS NOW) 
; elow/nlow is either solar flares *OR* attenuator motions!
;	elow = where(burst_es LT 30.,nlow)
;	front = where(burstraws.a2d_index LT 9,nfront)

; Determine the standard dev. (second moment) of the distr. of detectors about zero,
; a measure of concentration. Larger -> events are better dispersed in detector.
	IF max(burst_ss) lt 9 THEN BEGIN
		return_val = -5
		return
	ENDIF

	detw = where(burst_ss gt 17, ndetw)
	IF ndetw gt 0 THEN burst_ss[detw] -= 9
	h2 = histogram(burst_ss, min=9, binsize=1)
	nonzero = h2[where(h2 gt 0)]
	sorted = nonzero[reverse(sort(nonzero))]
	xf = findgen(n_elements(sorted))
	conc = sqrt(total(xf^2*sorted)/total(sorted))
	IF conc le 1 THEN BEGIN
		return_val = -6
		return
	ENDIF

; Calculate the full significance. Determine which Poisson lookup table to use.
	lambda = subevent_rate*burst_duration
	IF lambda ge 500.0 OR num_counts gt 500 THEN BEGIN
		return_val = -7
		return
	ENDIF 
	IF lambda ge 50.0 OR num_counts ge 100 THEN BEGIN
		probability = poissontable_loose[max([round(lambda*10)-1, 0]), num_counts]
	ENDIF ELSE BEGIN
		probability = poissontable_fine[max([round(lambda*5000)-1, 0]), num_counts]
	ENDELSE

; Evaluate the TGF to see if it gets sent to the website.
	return_val = tgfn2_evaluate(timescale_index, num_counts, burst_rate, probability)
	IF return_val ne 1 THEN return

; If we're still going strong, then it's time to output the TGF's information.
	tgfn2_output, event_time, ts, elist, tlow, thigh, filename, timescale_index, halvesdiff,  burst_rate, subevent_rate, num_counts, burst_duration, conc, probability, n_uld_events

end
