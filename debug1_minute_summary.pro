; Utility to load all save files
pro debug1_minute_summary

	k = find_file('./output/stage1_daily/*.sav')
	FOR i = 0, n_elements(k)-1 DO BEGIN
		restore, k[i]
		openw, lun, './debug/stage1_' + timestring + '_minute_debug.txt', /append, /get_lun
		printf, lun, minutes_array[uniq(minutes_array, sort(minutes_array))]
		h = histogram(minutes_array, binsize=1, locations=x)
		printf, lun, k[i]
		FOR j = 0, n_elements(x)-1 DO printf, lun, num2str(x[j]) + ': ' + num2str(h[j])
		printf, lun, ''
		printf, lun, ''
		free_lun, lun
	ENDFOR

end
