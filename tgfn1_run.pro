; TGFN1_RUN
; Runs Stage 1!

pro tgfn1_run


	; Load config file
	@tgfn_config

	; Create common blocks, eventlist object, and restore Poisson table.
	common triggers, trigger_structures
	common poisson, poissontable
	common objects, obssum, obstref, o
	o = hsi_eventlist()
	restore, 'tgfn1_poissontable.sav'

	; Current timestamp
	now = anytim(systim())
	

	; Backup the right number of days, begin at the beginning of that day.
	start_date = anytim(strmid(anytim(now - cfg1_days_back*86400L, /ccsds), 0, 10) + 'T00:00:00.000')


	; FOR loop through each day from n_days back to the present
	FOR this_date = start_date, now, 86400L DO BEGIN

		scan_start = systime(1)

		; Extract timestamp in YYYY-MM-DD form. This is used for filenames.
		timestr = strmid(anytim(this_date, /ccsds), 0, 10)

		; Load the current files
		tgfn1_dayfile, timestr, minutes_array, trigger_structures

		; Which minutes have we looked at? Continue if we're done with this day.
		k = where(minutes_array eq 0, n)
		IF n eq 0 THEN continue


		; Initialize objects for this day
		finish = min([this_date + 86400, now])
		ob = hsi_obs_summ_flag(obs_time_interval=[this_date, finish])
		obssum = ob->getdata()
		obstr = ob->get()
		obstref = obstr.ut_ref
		obj_destroy, ob

		; Cycle through each minute that hasn't been scanned yet
		FOR i = 0, n - 1 DO BEGIN

			tgfn1_checkminute, this_date + k[i]*60, return_val
			minutes_array[k[i]] = return_val

		ENDFOR


		; Trim the triggers and fill in lats/longs
		IF n_elements(trigger_structures) gt 1 THEN trigger_structures = trigger_structures[1:*]
		tgfn1_latlons
		tgfn1_dayfile, timestr, minutes_array, trigger_structures, /save
		tgfn_log, 1, timestr + ' scanned. Time elapsed: ' + num2str(round(systime(1) - scan_start)) + 's.'  


	ENDFOR


end
