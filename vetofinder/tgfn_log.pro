; TGFN_LOG
; General output logging for tgfn_* algorithm

pro tgfn_log, stage, message

	; Restore include file
	@tgfn_config

	IF cfg_log_to_screen eq 1 THEN print, message

	IF cfg_log_to_file ne 1 THEN return

	; Log for stage 1
	IF stage eq 1 THEN BEGIN
		openw, lun, cfg1_log_file, /append, /get_lun
	ENDIF ELSE BEGIN
		openw, lun, cfg2_log_file, /append, /get_lun
	ENDELSE

	printf, lun, anytim(systim(), /ccsds) + ' - ' + message
	free_lun, lun

end
