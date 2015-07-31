This folder contains the files for the TGF cron job. Like the original search, this is broken down into two stages. 
Files that are associated with Stage 1 are prefixed with "tgfn1_", and files associated with Stage 2 are prefixed with
"tgfn2_". A global configuration file, "tgfn_config.pro", contains easily-changed values for most of the major settings.
In all scripts, variables from this config file are prefixed with "cfg". They may be prefixed with "cfg1_" or "cfg2_" if they are 
only for Stage 1 or Stage 2, respectively.


STAGE 1:
Stage 1 is called by running "tgfn1_run". Stage 1 uses loose triggers to allow ~100 events/timescale/day. These events are stored in
a structure array, "trigger_structures". This structure contains the timestamp, timescale, latitude, and longitude for each event.
They are saved in the Stage 1 directory (set in the config file), in the "cron" subdirectory, in a save file of the form YYYY-MM-DD.
They are also put into trigger list text file. That text file contains the timestamp, timescale, latitude, longitude, and a flag for
whether or not the event has been examined by Stage 2 yet (0 if not, 1 if it has, 2 if it passed Stage 2). The save file also contains
an array of 1440 elements, one for each minute of the day, showing the Stage 1 status of the day. This allows the data to be scanned
retroactively if it's not immediately available.

Here's how Stage 1 works:


- tgfn1_run.pro:
  Goes day-by-day, starting from a few days back up to the present. Restores the .sav file (if it exists) and finds the minutes that
  haven't been scanned, or creates blank items. Goes minute-by-minute and calls tgfn1_checkminute. Finally, calls tgfn1_latlons and then
  re-saves the file.

- tgfn1_dayfile:
  Handles the .sav files. Either restores the current one, creates a blank file, or saves the current values.

- tgfn1_checkminute:
  Loads the data for each minute after checking the particle rates (tgfn1_particlerates), and then calls tgfn1_peakfind to hunt for peaks.
  Returns a value that will go into that 1440-element array to mark it complete, failed, or incomplete.

- tgfn1_particlerates:
  Checks the particle rates for the minute in particular. If they are too high, returns a bad value, so the minute will be skipped.
 
- tgfn1_peakfind:
  Hunts through the eventlist from tgfn1_checkminute for a given timescale. Creates a histogram, grabs Poisson probability of excesses,
  and for any candidates, adds them to the structure array.

- tgfn1_latlons:
  Called last. Takes the current structure array and trims to unique combinations of timestamp/timescale. Fills in the corresponding
  latitudes and longitudes, then saves to the overall text file for Stage 1.
