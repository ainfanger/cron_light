Readme: Vetofinder

The Vetofinder directory is a subdirectoy of Cron and is useful for finding out why certain events
were vetoed during Stage 1. For example, if Gjesteland triggered on an event that did not trigger 
in the cron algorithm, then the user can find out why by running vetofinder. It may just be that 
Stage1 did not run over that time during the cron job. 

Note that tgfn1_manual is called tgfn1_manual_debug in this directory to emphasize that this is a
new version of tgfn1_manual that is meant for debugging purposes only. 

