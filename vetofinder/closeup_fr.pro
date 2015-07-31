;specificaa: specific-arc-alanyzer
;the difference between this and arcanalyzer.pro is that
;this is built to look at the TGF events Paul sent me. So it
; isn't looking at the entire day and it doesn't look for low 
;concentration, rather it is triggered by high counts, 
; and then takes a screenshot - this way we can scroll
;through a bunch of these laters to make sure there aren't
;any hidden arcs that may need further cleansing.

pro closeup_fr, date,dt,shift=shift
shift=fcheck(shift,0.d )
      loadct,13  
      !p.multi=[0,5,2]
      !x.margin=[4,3]
 
;      directory=strjoin(date+'-images')
;      file_mkdir,directory

      ;opening the object at DATE with 50 Âs cushions (I believe)
      o=hsi_eventlist()
      seg=intarr(27)+1        	 
      d=o->getdata(obs_time_interval=anytim(date)+[-1.,1.],$
      a2d_index_mask=seg,time_range=[0,0])
      s=o->get()
      ttrig = anytim(date)
      t0 = anytim(strmid(date,0,19))

;What remains to be done:
;FIRST, convert: energy, not channel.
;          -> ULD (channel -1) get set directly to 30 MeV
;         Use date to get gain parameters, calculate energies
;         separately for a2d_index i+9 and a2d_index i+18
;         all this code should be in cleanelist
  kev_energy = findgen(n_elements(d))
  params = hsi_get_e_edges(gain_time_wanted = string(anytim(date, /atime)), $
                             /coeff_only)
  fuld = where(d.channel EQ -1 and d.a2d_index LT 9, nfuld)
  ruld = where(d.channel EQ -1 and d.a2d_index GE 9, nruld)
  fres = where(d.channel EQ -2 and d.a2d_index LT 9, nfres)
  rres = where(d.channel EQ -2 and d.a2d_index GE 9, nrres)
  kev_energy =  d.channel*params[d.a2d_index, 1]+params[d.a2d_index, 0]
  if nfuld GT 0 then kev_energy[fuld] = 5000.
  if nruld GT 0 then kev_energy[ruld] = 30000.
  if nfres GT 0 then kev_energy[fres] = 60000.
  if nrres GT 0 then kev_energy[rres] = 60000.
  t=s.ut_ref+(d.time)/(1024.d)^2


      tsec=anytim(date)-t0
      tmsec=tsec*1000.d
      xr=[-dt,dt]+shift

      !p.multi=[0,1,1]
      !x.margin=[12,3]
      window,0,xsize=800,ysize=600
      plot,[0],[0],xticks=3,$
	       /ylog,yrange=[1.,100000.],$
	       psym=5,color=255,$
               xrange=xr, xtitle='Time relative to '+date+' in ms',$
                          ytitle='Energy, keV'
      energy=0.
      for i=0,8 do begin
           w=where(d.a2d_index EQ 9+i or d.a2d_index EQ 18+i $
                 and abs(t-ttrig) le 0.5d ,nw)
	   if nw eq 0 then continue	
           tclose1 = t[w]-t0
           tclose2 = tclose1*1000.d
           e_close=kev_energy[w]
           tpl = tclose2-tmsec
           ww=where(tpl gt xr[0] and tpl lt xr[1],nww)
           if nww GT 0 then energy += total(e_close[ww])
           if nww GT 0 then print,i,nww,total(e_close[ww])
           oplot,tpl,e_close,psym=5,color=255-(8-i)*25,symsize=8.-i/1.4

           ;fronts
           w=where(d.a2d_index EQ i and abs(t-ttrig) le 0.5d ,nw)
	   if nw eq 0 then continue	
           tclose1 = t[w]-t0
           tclose2 = tclose1*1000.d
           e_close=kev_energy[w]
           tpl = tclose2-tmsec
           ww=where(tpl gt xr[0] and tpl lt xr[1],nww)
           if nww GT 0 then energy += total(e_close[ww])
           if nww GT 0 then print,i,nww,total(e_close[ww])
           oplot,tpl,e_close,psym=4,color=255-(8-i)*25,symsize=8.-i/1.4

      endfor
      print,'Total energy: ',energy/1000., ' MeV'
      oplot,[-dt,dt]+shift,[18000.,18000.],psym=0
      oplot,[-dt,dt]+shift,[2800.,2800.],psym=0,color=255
      oplot,[-dt,dt]+shift,[20.,20.],psym=0,linestyle=2,color=255
      filename=strjoin(strsplit(date+'_fr.png',$
               /extract),'-')
;      void = cgsnapshot(FILENAME=filename,nodialog=1)


;       file_move,filename,directory
;   openw,1, 'blank.png'
;   printf,1, 'this is so file_move does not complain'
;   close,1
;   file_move, '*.png',directory
   
   end


 
