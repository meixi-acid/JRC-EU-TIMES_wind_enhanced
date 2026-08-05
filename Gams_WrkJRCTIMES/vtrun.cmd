for %%s in (

CLI_MM

) do ( 
CALL gams %%s.dmp gdx=GAMSSAVE\%%s
GDX2VEDA GAMSSAVE\%%s times2veda.vdd %%s
)
pause