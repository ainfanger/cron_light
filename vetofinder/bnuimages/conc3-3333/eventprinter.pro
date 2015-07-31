pro eventprinter
	readcol, 'bergennotucsc.storm.withvetos',date, cat, veto, format='A,A,A', delimiter='!'
	ndate = anytim(date)
	uniqueindex = uniq(ndate,sort(ndate))
	times1=date[uniqueindex]
	veto=veto[uniqueindex]
	stop
	FOR i=0,n_elements(veto)-1 DO BEGIN
		closeup_fr,times1[i],3,title=veto[i],/postscript,filenameflag=veto[i]
	ENDFOR 
END