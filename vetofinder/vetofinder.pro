; Procedure: vetofinder
;
; Purpose:
;  This code will run tgfn1_manual on a given eventlist and then output all the vetos 
;  within that minute to veto.out, then it will read veto.out and find all the vetos
;  within 4 seconds of the events. Note that 4 seconds may seem long but it is to ensure
;  that the veto did not come from an SAA veto of an entire 4 seconds (see tgfn1_peakfind).
;
; Inputs: 
;  An eventlist in the form of dates only. 
; 
; Output: 
;  A text file filled with all the vetos, and an evenlist with vetos within 4s of the 
;  input events. 
;
; Author:
; Alex Infanger (UC Santa Cruz)
; For more info contact ainfange@ucsc.edu




pro vetofinder, eventlist
  readcol, eventlist,dates,format='A',delimiter='x'
  date1 = anytim(anytim(dates)-60d,/ccsds)
  date2 = anytim(anytim(dates)+60.d,/ccsds)
  FOR i=0, n_elements(dates)-1 DO BEGIN
     tgfn1_manual_debug, date1[i], date2[i],/offopt
  ENDFOR
  
; Begin 'thereader' 
	
  readcol, 'veto.out', vetos, cat, reasons, format='A,A,A',delimiter='!'

  time1 = anytim(vetos)
  time2 = anytim(dates)

  true_indexes = intarr(n_elements(time1))
  openw, lun, 'bergennotucsc.storm.withvetos',/GET_LUN
  
  for i=0,n_elements(time2)-1 do begin
  	diff = abs(time2[i]-time1)
  	event = where(diff le 4.d,net)
    if net eq 0 then printf,lun, dates(i) +' ' + '!'+ ' ' + '-1' + ' '+ '!' + ' ' + 'Poisson' 
    for j = 0,net-1 do begin
      printf, lun, dates[i]+ ' ' + '!'+ ' ' + cat[event[j]] + ' ' + '!' + ' ' + reasons[event[j]]
    endfor 
  endfor
  
  FREE_LUN,lun
end







end
