; TGFN1_MANUAL
; Run Stage 1 from a start period to a stop period.
; - start (IN): Any anytim()-friendly timestamp to begin searching at.
; - stop (IN): Any anytim()-friendly timestamp to stop searching at.
;
; Outputs a structure of triggers to manual/ directory in Stage 1 output with a timestamp


pro tgfn1_manual, start, stop,offopt=offopt


	; Load config file
	@tgfn_config
	
	; Create common blocks, eventlist object, and restore Poisson table.
	common triggers, trigger_structures
	common poisson, poissontable
	common objects, obssum, obstref, o
	o = hsi_eventlist()
	restore, '~/ainfanger/tgf/programs/Data/PoissonTables/tgfn1_poissontable.sav'
	trigger_structures = [stage1_struct]

	start_timestamp = anytim(start)
	stop_timestamp = anytim(stop)
	FOR i = start_timestamp, stop_timestamp, 60L DO BEGIN
		tgfn1_checkminute, i, return_val
	ENDFOR
        ;IF n_elements(trigger_structures eq 0) THEN BEGIN
        ;   print, 'nothing found.'
        ;ENDIF
        
        
    if keyword_set(offopt) then return 

        ; Trim list and get lat/lons
	trigger_structures = trigger_structures[1:*]
	tgfn1_latlons

	; Output
	basename = strmid(anytim(start_timestamp, /ccsds), 0, 10) + '_' + strmid(anytim(stop_timestamp, /ccsds), 0, 10)
	fullname = cfg_output + 'manual/' + strmid(anytim(start_timestamp, /ccsds), 0, 10) + '_' + strmid(anytim(stop_timestamp, /ccsds), 0, 10)
	save, filename=fullname + '.sav', start, stop, trigger_structures

	; Write to trigger_list file
	openw, lun, fullname + '.txt', /append, /get_lun
	FOR i = 0L, n_elements(trigger_structures)-1 DO printf, lun, trigger_structures[i].timestamp,$
		trigger_structures[i].timescale, trigger_structures[i].latitude, trigger_structures[i].longitude, 0		
	free_lun, lun


	print, 'All done! Trigger list is in ' + fullname + '.txt.'
	print, 'Call Stage 2 on this list with: '
	print, "tgfn2_run, trigger_file='" + basename + ".txt'"

end
