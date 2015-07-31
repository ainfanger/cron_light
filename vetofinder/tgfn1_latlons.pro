; TGFN1_LATLONS
; Grab the temporary Stage 1 output file, find latitude/longitude, and add to the main trigger file. 

pro tgfn1_latlons

	; Load config file & common block
	@tgfn_config
	common triggers, trigger_structures

	print, 'Before trim: ' + num2str(n_elements(trigger_structures)) + ' files.'

	; Merge timestamp and timescale and grab unique events.
	combos = trigger_structures[*].timestamp + '$' + string(trigger_structures[*].timescale)
	unique = uniq(combos, sort(combos))
	trigger_structures = trigger_structures[unique]

	print, 'After trim: ' + num2str(n_elements(trigger_structures)) + ' files'

	; Create timestamps and grab lats/longs
	timestamps = anytim(trigger_structures[*].timestamp)
	latlons1 = hsi_get_latlon(timestamps)
	latlons2 = hsi_get_latlon(timestamps, /sattrack)


	
	; Go through each time, determine lat/long
	FOR i = 0L, n_elements(timestamps)-1 DO BEGIN
		latlon1 = latlons1[*,i]
		latlon2 = latlons2[*,i]
		if latlon1[2] LT 0. then latlon = latlon2
		if latlon2[2] LT 0. then latlon = latlon1
		latitude = latlon[0]
		longitude = latlon[1]
		
		trigger_structures[i].latitude = latitude
		trigger_structures[i].longitude = longitude

	ENDFOR



end
