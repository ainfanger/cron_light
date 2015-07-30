; TGFN1_PARTICLERATES
; Checks particle rates for that specific minute and returns a flag for whether or not to proceed.
; - minute (IN): Timestamp (from anytim()) of the minute to check.
; Return values:
; 3: Error in monitor rate result
; 2: High particle rates
; 0: Particle rates are reasonable, proceed.


function tgfn1_particlerates, minute

	; Load config file
	@tgfn_config
	common objects, obssum, obstref, o

	omr = hsi_monitor_rate()
	master_md = omr->getdata(obs_time_interval=[minute - 10.0, minute + 70.0])
	ms = omr->get()
	obj_destroy, omr

	IF size(master_md, /type) ne 8 THEN return, 1
	

	particle_times = double(master_md.time) + ms.mon_ut_ref
	particle = total(master_md.particle_lo, 1)
	nel = n_elements(particle)-1
	particle_rates = make_array(nel+1, /byte)
	FOR i = 0l, nel DO BEGIN
		parmin = max([0, i - 2])
		parmax = min([nel, i + 2])

		; If particle rate is >= 10, then mark it as bad with a 1.
		IF mean(particle[parmin:parmax]) ge cfg1_max_particle_rate THEN particle_rates[i] = 1 ELSE particle_rates[i] = 0
	ENDFOR

	particle_times_min = min(abs(particle_times - minute), min_index)
	IF particle_rates[min_index] eq 1 THEN return, 2 ELSE return, 0
	



	
end
