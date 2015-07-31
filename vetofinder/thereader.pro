pro thereader
  readcol, 'veto.out', vetos, cat, reasons, format='A,A,A',delimiter='!'
  readcol, 'bergennotucsc.storm',true_dates, format='A',delimiter='!'

  time1 = anytim(vetos)
  time2 = anytim(true_dates)

  true_indexes = intarr(n_elements(time1))
  openw, lun, 'bergennotucsc.storm.withvetos',/GET_LUN
  
  for i=0,n_elements(time2)-1 do begin
  	diff = abs(time2[i]-time1)
  	event = where(diff le .010d,net)
    if net eq 0 then printf,lun, true_dates(i) +' ' + '!'+ ' ' + '-1' + ' '+ '!' + ' ' + 'Poisson' 
    for j = 0,net-1 do begin
      printf, lun, true_dates[i]+ ' ' + '!'+ ' ' + cat[event[j]] + ' ' + '!' + ' ' + reasons[event[j]]
    endfor 
  endfor
  
  FREE_LUN,lun
end
