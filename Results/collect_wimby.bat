set p=C:\Veda\Gams_Wrk_WIMBY_0509
for %%s in (


CLI_LL_no_au_ofwin  

) do (
gams collect_results_single_scenario_WIMBY.gms --Scenario=%%s --TIMESPath=%p%
)

PAUSE

