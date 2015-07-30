; TGFN1_CHECKMINUTE
; Checks one minute for peaks.
; - minute (IN): The anytim()-style timestamp for the start of the minute to check
; - return_val (OUT): A flag for the array of minutes, detailing what happened in this minute:
;       - 0: Minute hasn't been checked
;       - 2: High particle rate (skipped)
;       - 4: Bad data gathering.
;       - 1: Minute has been checked.


pro tgfn1_checkminute, minute, return_val


; Load config file and restore common blcoks
	@tgfn_config
	common objects, obssum, obstref, o
	return_val = 0

; Check particle rate
	particle_rate = tgfn1_particlerates(minute)
	IF particle_rate ne 0 THEN BEGIN
		IF particle_rate eq 1 THEN particle_rate = 0
		return_val = particle_rate
		IF particle_rate eq 2 THEN tgfn_log, 1, anytim(minute, /ccsds) + ' - MINUTE DROPPED: High particle rate'	
		return
	ENDIF

; Make an eventlist, load data in interval and 100ms on either side. This is rears only, that's the a2d_index_mask bit.
	d = o -> getdata(obs_time_interval = [minute - 0.1d, minute + 60.1d], $
		time_unit = 1, time_range = [0,0], $
		a2d_index_mask = [bytarr(9), bytarr(18)+1])

; Check several ways to see if we got no data, then check for bad data gathering a gap.
	IF size(d, /type) NE 8 THEN BEGIN
		return_val = 4
	ENDIF ELSE IF n_tags(d) EQ 0 THEN BEGIN
		return_val = 4
	ENDIF ELSE BEGIN
		wh = where(d.time ge 0, nwh)
		IF nwh eq 0 THEN return_val = 4
	ENDELSE

	IF return_val eq 4 THEN BEGIN
		return_val = 0 ;come back to this!
		tgfn_log, 1, anytim(minute, /ccsds) + ' - MINUTE DROPPED: Bad data'
		return
	ENDIF
	d = d[wh]

	;IF min(d.time) lt 0 THEN BEGIN
	;	return_val = 4
	;	return
	;ENDIF
	
	s = o -> get()  

; If G8 front is having transmitter noise (>25% of counts from G8), purge it *entirely*:
	g8f = where(d.a2d_index EQ 7, ng8f)
	IF float(ng8f)/float(n_elements(d)) gt 0.25 THEN d = d[where(d.a2d_index NE 7)]

; Clock corrections
	tfine = d.time/(1024.d)^2.
	realtime_all = anytim(s.ut_ref)+tfine

; Drop low energy events (items in channels <= 100)
	whall = where(d.channel GT 100, nall)
	IF nall eq 0 THEN BEGIN
		return_val = 4
		tgfn_log, 1, '' + anytim(minute, /ccsds) + ' - MINUTE DROPPED: All events in channels <= 100.'
		return
	ENDIF

	eventlist = realtime_all[whall] ; Actual times
	detectorlist = d[whall].a2d_index ; Detectors of items
	uall = uniq(d[whall].time/4) ; Find unique ones
	eventlist = eventlist[uall] ; Limit to uniques
	detectorlist = detectorlist[uall] ; Limit to uniques

	; Break minute up into fifteen 4s chunks
	m = min(eventlist)
	FOR ii = 0, 14 DO BEGIN
		wh = where(eventlist ge (m + ii*4. - 0.1) AND eventlist le (m + (ii+1)*4. + 0.1), n)
		IF n eq 0 THEN continue

		evt = eventlist[wh]
		det = detectorlist[wh]
	
		; Cycle through timescales and check for peaks
		FOR i = 0, n_elements(cfg_timescales)-1 DO BEGIN

			tgfn1_peakfind, minute, i, evt, det
			tgfn1_peakfind, minute, i, evt, det, /offset

		ENDFOR
	ENDFOR

	return_val = 1

end
