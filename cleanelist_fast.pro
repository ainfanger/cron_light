;Vetoes resets, image events, and multiple-ULD events (which 
;cannot be photons and are probably cosmic ray showers).  Usual
;real-coincidence from PPP document are supplemented by an
;extra width of window for the case of ULD events, since we
;don't really know how their window works.
;Modification 6/12/07: we will kill events that sit in more than 
;3 detectors, as being almost certainly cosmic ray showers; 
;mechanism is via "maxdets"

pro cleanelist_fast, d, kev_energy, elist, tlist, slist, used, maxdets=maxdets
  maxdets=fcheck(maxdets,3)

;  kev_energy = findgen(n_elements(d))
;  params = hsi_get_e_edges(gain_time_wanted = string(anytim(time0, /atime)), $
;                             /coeff_only)
;  fuld = where(d.channel EQ -t1 and d.a2d_index LT 9, nfuld)
;  ruld = where(d.channel EQ -1 and d.a2d_index GE 9, nruld)
;  kev_energy =  d.channel*params[d.a2d_index, 1]+params[d.a2d_index, 0]
;  if nfuld GT 0 then kev_energy[fuld] = 3000.
;  if nruld GT 0 then kev_energy[ruld] = 20000.

  used=bytarr(n_elements(d))
  elist=-1.0+fltarr(n_elements(d))
  tlist=-1l+lonarr(n_elements(d))
  slist=-2 +intarr(n_elements(d))   ;when segment=-1, that means multiple were added
  kth = 0l

  ;Clean out resets:
  wh = where(d.channel EQ -2,nwh)
  if nwh GT 0 then used[wh]=1

  ;Clean out bipolars and sum coincidences:
  for i=0l, n_elements(d)-1l do begin
;if (i mod 1000) EQ 0 then print,i
     if used[i] NE 0 then continue

     ilow=max([0,i-20])
     ihigh=min([n_elements(d)-1l ,i+20l ])
     sub=d[ilow:ihigh]
     lused=used[ilow:ihigh]
     countup = indgen(n_elements(sub))+ilow
     ;Select out ULDs for special treatment:
     expandi = bytarr(n_elements(sub))+ (d[i].channel EQ -1)
     widerange = where( sub.channel EQ -1 OR expandi )

     ;Logic for a front segment event:
     if d[i].a2d_index LT 9 then begin
        ;I'm an image count: front first, dt = 0 or 1
        thisfalse = where($
          (sub.a2d_index EQ d[i].a2d_index + 9 OR  $
           sub.a2d_index EQ d[i].a2d_index + 18 ) AND $
          (sub.time EQ d[i].time OR  $
           sub.time EQ d[i].time + 1 ) AND $
           countup GT i ,nthisfalse )
        if nthisfalse GT 0 then begin
                 used[i] = 1  
                 lused[i-ilow] = 1
                 continue
        endif

        ;Image counts in rear:
        falses =  where($
          (sub.a2d_index EQ d[i].a2d_index + 9 OR  $
           sub.a2d_index EQ d[i].a2d_index + 18 ) AND $
          (sub.time EQ d[i].time - 3 OR  $
           sub.time EQ d[i].time - 4 ) AND $
           countup LT i ,nfalse )
        if nfalse GT 0 then begin
                 used[falses+ilow] = 1  
                 lused[falses] = 1  
        endif

        ;Real coincidences (includes the current count itself!):
        reals = where( lused EQ 0 AND $
            ((sub.a2d_index LT 9) AND $
             (abs(sub.time - d[i].time) LE 1+expandi)) OR $
            ((sub.a2d_index GE 9) AND  $
             (sub.time - d[i].time LE 0+expandi AND sub.time - d[i].time GE -2-expandi )) , nreals)
        if nreals GT 0 then begin
          ndets = -1
          if nreals GT maxdets then begin
             occupied = bytarr(9)
             for j=0,nreals-1 do $
               occupied[sub[reals[j]].a2d_index MOD 9] = occupied[sub[reals[j]].a2d_index MOD 9]+1
             wh = where(occupied GT 0, ndets)
          endif
          esum = total(kev_energy[reals+ilow])
          if (esum LT 40000. and ndets LE maxdets) then begin
             elist[kth] = esum
             tlist[kth] = d[i].time
             if nreals EQ 1 then slist[kth]=d[i].a2d_index else slist[kth]=-1
             kth++
          endif
          used[reals+ilow]=2
        endif

    endif else begin
    ;Logic for a rear segment event:

        ;I'm an image count: rear first, dt = 3 or 4
        thisfalse = where($
          (sub.a2d_index EQ d[i].a2d_index - 9 OR  $
           sub.a2d_index EQ d[i].a2d_index - 18 ) AND $
          (sub.time EQ d[i].time + 3 OR  $
           sub.time EQ d[i].time + 4 ) AND $
           countup GT i ,nthisfalse )
        if nthisfalse GT 0 then begin
                 used[i] = 1  
                 lused[i-ilow] = 1
                 continue
        endif

        ;Image counts in front:
        falses =  where($
          (sub.a2d_index EQ d[i].a2d_index - 9 OR  $
           sub.a2d_index EQ d[i].a2d_index - 18 ) AND $
          (sub.time EQ d[i].time  OR  $
           sub.time EQ d[i].time - 1 ) AND $
           countup LT i ,nfalse )
        if nfalse GT 0 then begin
                 used[falses+ilow] = 1  
                 lused[falses] = 1  
        endif

        ;Real coincidences (includes the current count itself!):
         reals = where(lused EQ 0 AND $
          ( ((sub.a2d_index LT 9) AND $
             (sub.time - d[i].time GE 0-expandi AND sub.time - d[i].time LE 2+expandi )) OR $
            ((sub.a2d_index GE 9) AND  $
             (abs(sub.time - d[i].time) LE 1+expandi)) ), nreals )
        if nreals GT 0 then begin
          ndets = -1
          if nreals GT maxdets then begin
             occupied = bytarr(9)
             for j=0,nreals-1 do $
               occupied[sub[reals[j]].a2d_index MOD 9] = occupied[sub[reals[j]].a2d_index MOD 9]+1
             wh = where(occupied GT 0, ndets)
          endif
          esum = total(kev_energy[reals+ilow])
          if (esum LT 40000. and ndets LE maxdets) then begin
             elist[kth] = esum
             tlist[kth] = d[i].time
             if nreals EQ 1 then slist[kth]=d[i].a2d_index else slist[kth]=-1
             kth++
          endif
          used[reals+ilow]=2
      endif


    endelse

endfor

tlist = tlist[0:kth-1]
elist = elist[0:kth-1]
slist = slist[0:kth-1]

end



