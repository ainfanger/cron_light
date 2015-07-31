; TGFN1_DAYFILE:
; Handles the Stage 1 output files for a given day by loading, creating, or saving them.
;
; If flag "/save" is not set, we're grabbing the current file:
; - timestring (IN): YYYY-MM-DD string for the date to look for.
; - minutes_array (OUT): 1440-element integer array, with flags for each minute. See tgfn1_checkminute for details.
; - trigger_structures (OUT): Array of structures of all triggers. Format of structure is defined in tgfn1_config.pro.
;
; If flag "/save" is set, we're saving the current status:
; - timestring (IN): YYYY-MM-DD string for the date to look for.
; - minutes_array (IN): Same as above, but showing the current status.
; - trigger_structures (IN): Same as above, but containig the current triggers.

pro tgfn1_dayfile, timestring, minutes_array, trigger_structures, save=save

	; Load config file, create the expected filename.
	@tgfn_config
	filename = cfg1_output_directory + timestring + '.sav'


	; If we're loading the file
	IF n_elements(save) eq 0 THEN BEGIN

		; Check if the file exists. If so, restore it.
		IF file_test(filename) eq 1 THEN BEGIN
			restore, filename
			return
		ENDIF 

		; Otherwise, initialize the arrays
		minutes_array = intarr(1440)
		trigger_structures = [stage1_struct]


	; If we're saving the file
	ENDIF ELSE BEGIN

		; Save the events for the day
		save, filename=filename, minutes_array, trigger_structures, timestring

		; Write to trigger_list file
		openw, lun, cfg_trigger_list, /append, /get_lun
		FOR i = 0L, n_elements(trigger_structures)-1 DO printf, lun, trigger_structures[i].timestamp,$
			trigger_structures[i].timescale, trigger_structures[i].latitude, trigger_structures[i].longitude, 0		
		free_lun, lun

	ENDELSE


end
