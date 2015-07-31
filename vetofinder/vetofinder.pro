pro vetofinder
  readcol, 'bergennotucsc.storm',dates, format='A',delimiter='x'
  date1 = anytim(anytim(dates)-60d,/ccsds)
  date2 = anytim(anytim(dates)+60.d,/ccsds)
  FOR i=0, n_elements(dates)-1 DO BEGIN
     tgfn1_manual, date1[i], date2[i],/offopt
  ENDFOR
  
end
