; TGFN2_RUN
; Runs Stage 2!
; - trigger_file (IN): (Optional!) Trigger list from Stage 1 to analyze, in the manual/
;   directory. If not specified, cfg_trigger_list is used instead.

pro tgfn2_run, trigger_file=trigger_file

	; Load config file
	@tgfn_config

	; Start time
	start = systime(1)
	tgfn_log, 2, '- - - - - START STAGE 2 - - - - - -'

	; Restore poisson table, create objects, and define common blocks
	common poisson, poissontable_fine, poissontable_loose
	common objects, o, ob
	common environment, output_directory

	; If we're calling this manually (trigger file is specified), set some variables.
	IF n_elements(trigger_file) eq 0 THEN BEGIN
		trigger_list = cfg_trigger_list
		output_directory = cfg_output + 'stage2_events/'
	ENDIF ELSE BEGIN
		trigger_list = cfg_output + 'manual/' + trigger_file
		print, trigger_list
		output_directory = cfg_output + 'manual/' + strmid(trigger_file, 0, strlen(trigger_file) - 4) + '/'
		file_mkdir, output_directory
	ENDELSE

	; Load Stage 1 events
	readcol, trigger_list, timestamps, timescales, latitudes, longitudes, stage2status, format='a,i,d,d,i'

	; Trim to events not yet checked by Stage 2
	not_checked = where(stage2status eq 0, n)
	IF n eq 0 THEN return



	
	restore, 'tgfn2_poissontable.sav'
	o = hsi_eventlist()
	ob = hsi_obs_summ_flag()

	; Cycle through the events
	num_events = n_elements(timestamps)
	FOR i = 0L, num_events-1 DO BEGIN

		IF stage2status[i] ne 0 THEN continue
		tgfn2_checkevent, timestamps[i], timescales[i], return_val		
		stage2status[i] = return_val

		; Log the result and match error codes
		message = ''
		CASE return_val OF
			1: message = 'PASS - ' + timestamps[i]
			-1: message = 'FAIL - ' + timestamps[i] + ': Bad data'
			-2: message = 'FAIL - ' + timestamps[i] + ': Attenuator motion'
			-3: message = 'FAIL - ' + timestamps[i] + ': Excessive burstrate'
			-4: message = 'FAIL - ' + timestamps[i] + ': Bad binning'
			-5: message = 'FAIL - ' + timestamps[i] + ': No events in rear detectors'
			-6: message = 'FAIL - ' + timestamps[i] + ': Bad concentration parameter calculation'
			-7: message = 'FAIL - ' + timestamps[i] + ': Outside bounds of Poisson lookup'
			-8: message = 'SKIP - ' + timestamps[i] + ': Too few counts'
			-9: message = 'SKIP - ' + timestamps[i] + ': Too low of a burstrate'
			-10: message = 'SKIP - ' + timestamps[i] + ': Too probable'
		ENDCASE
		IF strlen(message) gt 1 THEN tgfn_log, 2, message + ' (' + num2str(cfg_timescales[timescales[i]], format='(f5.2)') + 'ms)'

	ENDFOR

	; Update triggers file
	openw, lun, trigger_list, /get_lun
	FOR i = 0L, num_events-1 DO printf, lun, timestamps[i], timescales[i], latitudes[i], longitudes[i], stage2status[i]
	free_lun, lun


	tgfn_log, 2, '- - - Stage 2 finished for ' + trigger_list + '. ' + num2str(round(systime(1) - start)) + 's elapsed.'

end
