pro tgfn2_manual, timestamp

	; Restore include
	@tgfn_config

	; Restore poisson table, create objects, and define common blocks
	common poisson, poissontable_fine, poissontable_loose
	common objects, o, ob
	common environment, output_directory

	restore, 'tgfn2_poissontable.sav'
	o = hsi_eventlist()
	ob = hsi_obs_summ_flag()
	output_directory = cfg_output + 'manual/stage2_misc/'

	; Cycle through timescales and call checkevent on each:
	ts_result = intarr(n_elements(cfg_timescales))
	FOR i = 0, n_elements(cfg_timescales)-1 DO BEGIN
		tgfn2_checkevent, timestamp, i, return_val
		ts_result[i] = return_val
	ENDFOR

	; Output results all at once for easier reading
	FOR i = 0, n_elements(cfg_timescales)-1 DO BEGIN
		
		return_val = ts_result[i]

		; Log the result
		message = ''
		CASE return_val OF
			1: message = 'PASS - ' + timestamp
			-1: message = 'FAIL - ' + timestamp + ': Bad data'
			-2: message = 'FAIL - ' + timestamp + ': Attenuator motion'
			-3: message = 'FAIL - ' + timestamp + ': Excessive burstrate'
			-4: message = 'FAIL - ' + timestamp + ': Bad binning'
			-5: message = 'FAIL - ' + timestamp + ': No events in rear detectors'
			-6: message = 'FAIL - ' + timestamp + ': Bad concentration parameter calculation'
			-7: message = 'FAIL - ' + timestamp + ': Outside bounds of Poisson lookup'
			-8: message = 'SKIP - ' + timestamp + ': Too few counts'
			-9: message = 'SKIP - ' + timestamp + ': Too low of a burstrate'
			-10: message = 'SKIP - ' + timestamp + ': Too probable'
		ENDCASE
		IF strlen(message) gt 1 THEN tgfn_log, 2, message + ' (' + num2str(cfg_timescales[i], format='(f5.2)') + 'ms)'
	ENDFOR

end
