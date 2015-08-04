; CONFIG FILE
; Contains all configuration settings for TGF search cron job.
; Settings that only apply to Stage 1 are prefaced with "cfg1_".
; Settings that only apply to Stage 2 are prefaced with "cfg2_".
; Settings that apply to both are prefaced with "cfg_".


; SETTINGS FOR BOTH STAGES

	; Timescales (milliseconds):
  	cfg_timescales = [0.06, 0.1, 0.3, 1.0, 3.0, 10.0, 30.0]

	; Output directory
	cfg_output = './output/interanneal/'

	; Logging. Set to 1 to enable logging to file/screen
	cfg_log_to_file = 1
	cfg_log_to_screen = 0

	; Trigger list file
	cfg_trigger_list = cfg_output + 'trigger_list.txt'

    ; Detectors to use (currently rears only)
    cfg_a2d_index_mask = [bytarr(9),bytarr(18)+1]

    ; Threshold on channels 
    cfg_threshchans = [dblarr(18)+150.d,dblarr(9)]

; STAGE 1 SETTINGS
	; Days back to begin looking.
	cfg1_days_back = 200

	; Output directory for daily .sav files
	cfg1_output_directory = cfg_output + '/stage1_daily/'

	; Log file
	cfg1_log_file = cfg_output + 'stage1_log.txt'
	
	; Format of trigger structure
	stage1_struct = {stage1_struct, $
		timestamp: '', $		; YYYY-MM-DDTHH:MM:SS.ZZZ format timestamp
		timescale: 0, $			; Timescale that event triggered in
		latitude: 0.d, $		; Lat
		longitude: 0.d $		; Long
	}



	; Poisson probabilities -- each event must be below this probability to make the list.
	;    These were adjusted so that ~100 events per day pass. These are ordered the same as
	;    "timescales" above, so for example the 3rd element in this array is the _max_ probability
	;    allowed for events on the 0.3ms timescale to pass Stage 1.
	

	cfg1_max_probabilities = [2.0e-10, 1.0e-9, 1.22e-7, 1.1e-7, 9.0e-7, 2e-6, 8.8e-7]     ; STRICT 

	; cfg1_max_probabilities = [1.0e-9, 1.0e-8, 1.0e-6, 1.1e-6, 9.e-6, 2e-5, 8.8e-6] ; LOOSE

	; Maximum particle rates
	cfg1_max_particle_rate = 10


; STAGE 2 SETTINGS

	; Output directory for events
	cfg2_output_directory = cfg_output + '/stage2_events/'

	; Log file
	cfg2_log_file = cfg_output + 'stage2_log.txt'

	; Amoutn of data surrounding event to select
	cfg2_datawindow = 2.15d

	; THRESHOLDS
	; These thresholds are applied in Stage 2 and should be looser than the final ones. This is to reduce the number of files.
	; The index in these arrays corresponds to the index in cfg_timescales (eg, cfg2_min_counts[3] is the minimum
	; number of counts allowed for the 1.0ms timescale.

	;                      [ 60us, 100us, 300us,   1ms,   3ms,  10ms,  30ms]
	cfg2_min_counts =      [    4,     4,     6,     7,     8,    15,    25]
	cfg2_min_burst_rate =  [   25,    10,     7,     7,     5,     5,     4]
	cfg2_max_probability = [5.e-5, 1.e-5, 1.e-5, 5.e-5, 1.e-4, 1.e-6, 1.e-6]


	; Number of bins adjacent to peak to show in histograms
	cfg2_adjacent_bins = 30
