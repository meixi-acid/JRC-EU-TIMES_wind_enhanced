$TITLE SMALL UTILITY TO COLLECT RESULTS TO EXCEL FROM VEDA FILES
$TITLE SMALL UTILITY TO COLLECT RESULTS TO EXCEL FROM VEDA FILES

$OFFLISTING
$onWarning

* $call del out*.txt out*.gdx *.~gm"
$if not set TIMESPath $abort --TIMESPath for the working directory is missing
$if not set Scenario $abort --Scenario name is missing

* execute "copy results_template.xlsx %SCENARIO%.xlsx"
execute "copy results_template_WIMBY.xlsb %SCENARIO%.xlsb"
sets
         v vintage/1940*2200,0,"-","¤",NONE/
         t(v) period /2019*2200,"-", NONE/
*rt(t) reporting period /2019,2020,2025,2030,2035,2040,2045,2050,2055,2060/
         rt(t) reporting period /2019,2050/
         ts timeslices /ANNUAL,S,F,W,R,SD,SN,SP,FD,FN,FP,WD,WN,WP,RD,RN,RP, "-", NONE , season, weekly, daynite/
         seas(ts) seasonal timeslices /S, F, W, R/
         seas_ts(ts, ts) timeslice seasons mapping / S.(SD,SN,SP), F.(FD,FN,FP), W.(WD,WN,WP), R.(RD,RN,RP) /;
alias (s,ts,ss), (rt2,rt);

$onechov > read_VDE_dim%SCENARIO%1.awk
BEGIN {FS = ","}
{a[$1]++ } END { for (b in a) { print b }}
END {}
$offecho
$onechov > read_VDE_dim%SCENARIO%2.awk
BEGIN {FS = ","}
{a[$2]++ } END { for (b in a) { print b }}
END {}
$offecho
$onechov > read_VDE_dim%SCENARIO%3.awk
BEGIN {FS = ","}
{a[$3]++ } END { for (b in a) { print b }}
END {}
$offecho

$call awk -f read_VDE_dim%SCENARIO%1.awk %TIMESPATH%\%SCENARIO%.vde > dim%SCENARIO%1.gms
$call awk -f read_VDE_dim%SCENARIO%2.awk %TIMESPATH%\%SCENARIO%.vde > dim%SCENARIO%2.gms
$call awk -f read_VDE_dim%SCENARIO%3.awk %TIMESPATH%\%SCENARIO%.vde > dim%SCENARIO%6.gms


set
dim1 veda items/
$include dim%SCENARIO%1.gms
"-"
/

$onecho>>dim%SCENARIO%2.gms
*NONE
$offecho

dim2 regions/
$include dim%SCENARIO%2.gms

/

dim3 processes and commodities/
$include dim%SCENARIO%6.gms
"-"

*********************
* WARNING!!
* Insert here the commodity groups manually
*
FINREN
UDCG_AllHeat
UDCG_CHPOutputforRENAct
CG_ETBE
CG_ETHA
CG_EMHV
CG_HVO
CG_DSKR-SB
IIS_Gases
/

;


alias (dim2, Region);
alias (Attribute,Commodity,Process,UserConstraint,dim3);
$call del dim%SCENARIO%1.gms dim%SCENARIO%2.gms dim%SCENARIO%6.gms *%SCENARIO%*.awk

set vde(dim1,dim2,dim3) veda elements definition data
/
$ondelim
$include %TIMESPATH%\%SCENARIO%.vde
$offdelim
/
;

alias (commodity, process, attribute, user_constraint,dim3);

parameter veda_vdd(Attribute,Commodity,Process,t,Region,v,ts,UserConstraint) veda vd results
*  Dimensions- Attribute;Commodity;Process;Period;Region;Vintage;TimeSlice;UserConstraint;PV
$ondelim
/
$include %TIMESPATH%\%SCENARIO%.vd
/;
$offdelim

sets
*    eu27(Region) eu-27 member states /AT,BE,BG,CY,CZ,DE,DK,EE,ES,FI,FR,EL,HR,HU,IE,IT,LT,LU,LV,MT,NL,PL,PT,RO,SE,SI,SK/ 
    rpt_reg reporting regions /#region, EU-27/
    eu27(rpt_reg) eu-27 member states /EL,IE,AT,DE,Mt,FI,IT,SI,CY,PL,RO,BE,CZ,LT,SK,LU,BG,EE,LV,NL,DK,ES,HR,FR,HU,PT,SE/
    fuel all reporting fuels /coal,coal_ccs,oil,oil_ccs,gas,gas_ccs,nuclear,hydro,biogas,bioliquids,biomass,biomass_ccs,wind,solar,env_heat,heat,geo_oce,elec,h2,other,efuels,egases,green_efuels/
* emissions commodities produced only from CCS processes (used to identify CCS processes in the model)
    CO2_ccs(Commodity) CO2 emissions sequestrated /AGRSCO2N,COMSCO2N,ELCSCO2N,ELCSCO2GN,INDSCO2N,INDSCO2GN,SUPSCO2N,SUPSCO2GN/
    ccs_fuels(fuel) fuels for ccs /coal_ccs,gas_ccs,oil_ccs,biomass_ccs/
* fuels related to e-gases and and e-liquids consumed in the sector
    ge_gases_com(Commodity) only green e-gases /GASP2G_G/
    ge_liquids_com(Commodity) only green e-liquids /SYNGDST,SYNGGSL,SYNGKER,SYNGOTH/
;
alias(fuel2, fuel);
parameter cf(process) conversion factors on activities to PJ;

cf(process)=1;


**********************************************
*** CREATE PROCESS SUBSETS USED IN THE TABLES 
**********************************************

set python_prc(process) processes to look up with python code;

python_prc(process)=yes;
python_prc(process)$sameas(process,"¤")=no;
python_prc(process)$sameas(process,"¤")=no;


* Overarching sets with processes per energy sector 
sets   
    pri_prc(process) subset of processes involved in the primary production table 
    nimp_prc(process) subset of processes involved in the net imports table
    nimp_end_eu_prc(process) subset of processes that are involved in the endogenous EU trade 
    dhprd_prc_py(process) subset of processes involved in the district heating production table according to their name formation
    dhprc_elc_py(process) subset of electric heat pumps that are connection to district heating production
    rsd_dh_prc_py(process)
    com_dh_prc_py(process)
    hpprd_prc_py(process) on-site heat pumps
    elc_nres_sc_py(process) 
    elc_nres_sh_py(process)
    elc_nres_wh_py(process)
    synprd_prc_py(process) subset of processes involved in the synthetic fuels table according to their name formation
    synblq_prc_py(process) subset of processes producing bioliquids according to their name formation
    synbgs_prc_py(process) subset of processes producing biogases according to their name formation
    synflq_prc_py(process) subset of processes producing fossil liquids according to their name formation
    synfgs_prc_py(process) subset of processes producing fossil gases according to their name formation
    synelq_prc_py(process) subset of processes producing e-liquids according to their name formation
    synegrlq_prc_py(process) subset of processes producing green e-liquids according to their name formation
    synegs_prc_py(process) subset of processes producing e-gases according to their name formation
    synegrgs_prc_py(process) subset of processes producing green e-gases according to their name formation
    iis_ind_py(process) subset of processes in Iron and Steel Industry   
    inf_ind_py(process) subset of processes in Non-Ferrous Metals Industry
    ich_ind_py(process) subset of processes in Chemicals Industry
    ipp_ind_py(process) subset of processes in Paper and Pulp Industry
    inm_ind_py(process) subset of processes in Non Metallic Minerals Industry
    ioi_ind_py(process) subset of processes in Other Industry
    nen_py(process) subset of processes in Non-Energy Uses
    iot_prc_py(Process) Other industrial processes consuming heat produced by on-site boilers or CHPs or distric heating
    bioe_prc_py(Process) biofuel production processes producing also electricity  (all with and without CCS)
    bioe_ccs_prc_py(Process) biofuel production processes producing also electricity with CCS
    eleTD_prc_py(Process) electricity Transmissoin and Distribution processes
    h2TD_prc_py(Process) hydrogen Transmissoin and Distribution processes
    indTD_prc_py(Process) industry Transmissoin and Distribution processes
    comTD_prc_py(Process) commercial Transmissoin and Distribution processes
    traTD_prc_py(Process) transport Transmissoin and Distribution processes
    rsdTD_prc_py(Process) residential Transmissoin and Distribution processes
    agrTD_prc_py(Process) residential Transmissoin and Distribution processes
    tra_carlpg_py(Process) conventional and hybrind LPG cars
    tra_cargsl_py(Process) conventional and hybrind gasoline cars
    tra_carelc_py(Process) electric cars
    tra_carcng_py(Process) conventional and hybrind LPG cars
    tra_cardsl_py(Process) conventional and hybrind diesel cars
    tra_carhh2_py(Process) hydrogen cars
    tra_lcvcng_py(Process) compressed gas LCV vehicles
    tra_lcvdsl_py(Process) diesel LCV vehicles
    tra_lcvelc_py(Process) electric LCV vehicles
    tra_lcvgas_py(Process) gasoline LCV vehicles
    tra_lcvhh2_py(Process) hydrogen LCV vehicles
    tra_lcvlpg_py(Process) lpg LCV vehicles
    tra_hdtcng_py(Process) compress gas trucks
    tra_hdtdsl_py(Process) diesel trucks
    tra_hdtelc_py(Process) electric trucks
    tra_hdthh2_py(Process) hydrogen trucks
    

;

parameter
    aux_all(process,rt,region) temporary parameter to hold consumption or production accross all commodities of a process 
    aux_com(commodity,process,rt,region) temporary parameter to hold consumption or production per commodity of a process 
    aux_com2(commodity,process,rt,region) temporary parameter to hold consumption or production per commodity of a process 
;

* The following code select TIMES processes based on their name formation
embeddedCode Python:
pri_prc = []
nimp_prc = []
nimp_end_eu_prc = []
dhprd_prc_py = []
dhprc_elc_py = []
hpprd_prc_py = []
rsd_dh_prc_py = []
com_dh_prc_py = []
elc_nres_sc_py = []
elc_nres_sh_py = []
elc_nres_wh_py = []
synprd_prc_py = []
synblq_prc_py = []
synbgs_prc_py = []
synflq_prc_py = []
synfgs_prc_py = []
synelq_prc_py = []
synegs_prc_py = []
iis_ind_py = []
inf_ind_py = []
ich_ind_py = []
ipp_ind_py = []
inm_ind_py = []
ioi_ind_py = []
nen_py = []
iot_prc_py=[]
bioe_prc_py = []
bioe_ccs_prc_py=[]
synegrlq_prc_py=[]
synegrgs_prc_py=[]
synegrlq_prc_py=[]
eleTD_prc_py=[]
h2TD_prc_py=[]
indTD_prc_py=[]
comTD_prc_py=[]
rsdTD_prc_py=[]
traTD_prc_py=[]
agrTD_prc_py=[]
tra_carlpg_py=[]
tra_cargsl_py=[]
tra_carelc_py=[]
tra_carcng_py=[]
tra_cardsl_py=[]
tra_carhh2_py=[]
tra_lcvcng_py=[]
tra_lcvdsl_py=[]
tra_lcvelc_py=[]
tra_lcvgas_py=[]
tra_lcvhh2_py=[]
tra_lcvlpg_py=[]
tra_hdtcng_py=[]
tra_hdtdsl_py=[]
tra_hdtelc_py=[]
tra_hdthh2_py=[]


for p in gams.get('python_prc'):

# Select processes starting with MIN (Primary Production)
   if p.startswith('MIN'):
       pri_prc.append(p)

# Select processes starting with IMP, EXP, TB_ , TU_, GI- (Net Imports)
   if p.startswith('EXP') or p.startswith('IMP') or p.startswith('TB_') or p.startswith('TU_') or p.startswith('GI-'):
       nimp_prc.append(p)
       
   if p.startswith('UNPACK'):
       nimp_prc.append(p)

   if (p.startswith('TB_') or p.startswith('TU_') or p.startswith('GI-')) and (p.find('CH')<0 and p.find('NO')<0 and p.find('UK')<0):
       nimp_end_eu_prc.append(p)

# Select biofuel processes producing electricity too
   if p.startswith('BRF2'):
        bioe_prc_py.append(p)
        if (p.find('CCS')>-1) or (p.find('CCU')-1) or (p.find('Seq')>-1):
            bioe_ccs_prc_py.append(p)

# Select processes starting with CHP, EAUTO, ECHP, PU, EEHP, HHTH, or S_CCUS_P2G, or contain -CHP- 
   if p.startswith('CHP')or(p.find('-CHP')>-1)or p.startswith('EAUTO')or p.startswith('ECHP_')or p.startswith('PU')or p.startswith('EEHP')or p.startswith('HHTH')or p.startswith('S_CCUS_P2G')or p.startswith('BWOOGAS')or p.startswith('SCOA'):
       dhprd_prc_py.append(p)
   if p.find('_HEAT')>-1:
        dhprd_prc_py.append(p)

#Select processes that are electric heat pumps for district heating 
   if p.startswith('HHTHELC'):
       dhprc_elc_py.append(p)
       
#Select processes starting with R_ES_SH_*ELC which are on-site residential heat pumps that produce water and space heating
   if p in ['R_ES-SH-DH-70_ELC02','R_ES-SH-DH-70_ELC04','R_ES-SH-DH-70_ELC05',
   'R_ES-SH-DH-70_ELC06','R_ES-SH-DH-70_ELC07','R_ES-SH-DH-70_ELC08','R_ES-SH-DH-70_ELC09',
   'R_ES-SH-DH-70_ELC10','R_ES-SH-DH-70_ELC11','R_ES-SH-DH_ELC02','R_ES-SH-DH_ELC04',
   'R_ES-SH-DH_ELC05','R_ES-SH-DH_ELC06','R_ES-SH-DH_ELC07','R_ES-SH-DH_ELC08',
   'R_ES-SH-DH_ELC09','R_ES-SH-DH_ELC10','R_ES-SH-DH_ELC11','R_ES-SH-SD_ELC02',
   'R_ES-SH-SD_ELC04','R_ES-SH-SD_ELC05','R_ES-SH-SD_ELC06','R_ES-SH-SD_ELC07',
   'R_ES-SH-SD_ELC08','R_ES-SH-SD_ELC09','R_ES-SH-SD_ELC10','R_ES-SH-SD_ELC11','R_ES-SH-FL_ELC02',
   'R_ES-SH-FL_ELC04','R_ES-SH-FL_ELC05','R_ES-SH-FL_ELC06','R_ES-SH-FL_ELC07',
   'R_ES-SH-FL_ELC08','R_ES-SH-FL_ELC09','R_ES-SH-FL_ELC10','R_ES-SH-FL_ELC11',
   'R_ES-SH-DH-70_ELC01','R_ES-SH-DH_ELC01','R_ES-SH-DH_ELC01''R_ES-SH-SD_ELC01','R_ES-SH-FL_ELC01']:
        hpprd_prc_py.append(p)

#Select residential district heating processes 
   if p in ['R_ES-SH-DH_HET','R_ES-SH-DH_HET01','R_ES-SH-DH-70_HET','R_ES-SH-DH-70_HET01','R_ES-SH-FL_HET','R_ES-SH-FL_HET01',
    'R_ES-SH-SD_HET','R_ES-SH-SD_HET01','R_ES-WH-DH_HET','R_ES-WH-FL_HET','R_ES-WH-SD_HET']:
        rsd_dh_prc_py.append(p)
         
#Select non-residential district heating processes 
   if p.startswith('C_ES') and (p.endswith('HET') or p.endswith('HET01')):    
        com_dh_prc_py.append(p)        
        
#Select processes starting with C_ES_SH_*ELC which are non-residential heatpumps + airconditioner +electric chiller?
   if p.startswith('C_ES-SC-HO_ELC') or p.startswith('C_ES-SC-HR_ELC') or p.startswith('C_ES-SC-OF_ELC') or p.startswith('C_ES-SC-SL_ELC')or p.startswith('C_ES-SC-SR_ELC')or p.startswith('C_ES-SC-SS_ELC'):
        elc_nres_sc_py.append(p)

#Select processes starting with C_ES_SH_*ELC which are non-residential heatpumps + airconditioner +electric chiller?
   if p.startswith('C_ES-SH-HO_ELC') or p.startswith('C_ES-SH-HR_ELC') or p.startswith('C_ES-SH-OF_ELC') or p.startswith('C_ES-SH-SL_ELC')or p.startswith('C_ES-SH-SR_ELC')or p.startswith('C_ES-SH-SS_ELC'):
        elc_nres_sh_py.append(p)

#Select processes starting with C_ES_SH_*ELC which are non-residential heatpumps + airconditioner +electric chiller?
   if p.startswith('C_ES-WH-HO_ELC') or p.startswith('C_ES-WH-HR_ELC') or p.startswith('C_ES-WH-OF_ELC') or p.startswith('C_ES-WH-SL_ELC')or p.startswith('C_ES-WH-SR_ELC')or p.startswith('C_ES-WH-SS_ELC'):
        elc_nres_wh_py.append(p)

# Select processes starting with BBLQM or S_CCU or SGASD or SCOAG or SCOAD or BWOOG or BBLQG or BSLUG or SCOAM or SGASM or BRF1_ or BRF2_ or BBLQ
   if p.startswith('BBLQ') or p.startswith('S_CCU') or p.startswith('SGASD') or p.startswith('SGASM') or p.startswith('SCOAD') or p.startswith('SCOAG') or p.startswith('SCOAM') or p.startswith('MINBIOGAS'):
       synprd_prc_py.append(p)
# Split synfuel processes according to the type of the output product (bioliquid, biogas, fossil-liquid, fossil-gas, e-liquid, e-gas)
       if p.startswith('BWOO') or p.startswith('BSL') or p.startswith('BBLQG') or p.startswith('MINBIOGAS'):
           synbgs_prc_py.append(p)
       elif p.startswith('BRF') or p.startswith('BBLQM') or p.startswith('BBLQD') or p.startswith('BBLQF'):
           synblq_prc_py.append(p)
       elif p.startswith('SCOAM') or p.startswith('SGASM') or p.startswith('SGASD') or p.startswith('SCOAD'):    
           synflq_prc_py.append(p)
       elif p.startswith('SCOAG'):    
           synfgs_prc_py.append(p)
       elif p.startswith('S_CCUS_P2G'):
            synegs_prc_py.append(p)
       elif p.startswith('S_CCUS_G_P2G'):
            synegrgs_prc_py.append(p)
       else:
           if p.find('_G_')>-1:
                synegrlq_prc_py.append(p)
           else:
                synelq_prc_py.append(p)

           
   elif p.startswith('BWOOG') or p.startswith('BSLU') or p.startswith('BRF1_') or p.startswith('BRF2_'):
        synprd_prc_py.append(p)
        
# Split synfuel processes according to the type of the output product (bioliquid, biogas, fossil-liquid, fossil-gas, e-liquid, e-gas)
        if p.startswith('BWOO') or p.startswith('BSL') or p.startswith('BBLQG'):
            synbgs_prc_py.append(p)
        elif p.startswith('BRF') or p.startswith('BBLQM') or p.startswith('BBLQD') or p.startswith('BBLQF'):
            synblq_prc_py.append(p)
        elif p.startswith('SCOAM') or p.startswith('SGASM') or p.startswith('SGASD') or p.startswith('SCOAD'):    
            synflq_prc_py.append(p)
        elif p.startswith('SCOAG'):    
            synfgs_prc_py.append(p)
        elif p.startswith('S_CCUS_P2G'):
            synegs_prc_py.append(p)
        elif p.startswith('S_CCUS_G_P2G'):
            synegrgs_prc_py.append(p)
        else:
           if p.find('_G_')>-1:
                synegrlq_prc_py.append(p)
           else:
                synelq_prc_py.append(p)
    

# Select Iron and Steel industrial processes (excluding blast furnances)
   if p.startswith('IIS') and (p.find('BLA')==-1):
        iis_ind_py.append(p)
  
# Select Non-Ferrous Metalsindustrial processes
   if p.startswith('IAL') or p.startswith('ICU') or p.startswith('INF'):
        inf_ind_py.append(p)

# Select Chemicals industrial processes
   if p.startswith('IAM') or p.startswith('ICH') or p.startswith('ICL'):
        ich_ind_py.append(p)
        
# Select Paper and Pulp  industrial processes
   if p.startswith('IPP'):
        ipp_ind_py.append(p)

# Select Non Metalic Minerals industrial processes
   if p.startswith('INM') or p.startswith('ILM') or p.startswith('IGF') or p.startswith('IGH') or p.startswith('ICM'):
        inm_ind_py.append(p)
        
# Select Other industrial processes
   if p.startswith('IOI') :
        ioi_ind_py.append(p)
        
# Select Non Energy Uses processes
   if p.startswith('NEU') :
        nen_py.append(p)
    
# Select other industry processes
   if p.startswith('I') and (p.find('OTH-NRG')>-1) :
        iot_prc_py.append(p)
        
# Select electricity T&D processes
   if p.find('EVTRANS')>-1 or p.startswith('GI-') or p.find('BAT')>-1 or p.find('CAES')>-1 or p.find('ESTHYDPS')>-1:
        eleTD_prc_py.append(p)

# Select hydrogen T&D processes
   if (p.find('IND')>-1 or p.find('AGR')>-1 or p.find('COM')>-1 or p.find('RSD')>-1 or p.find('TB')>-1 or p.find('TRA')>-1 or p.find('ST')>-1) and p.find('H2')>-1 :
        h2TD_prc_py.append(p)
        
# Select industry T&D processes
   if p.startswith('IND') and (p.find('00')>-1 or p.find('01')>-1) and p.find('H2')==-1:
        indTD_prc_py.append(p)
        
# Select commercial T&D processes
   if p.startswith('COM') and (p.find('00')>-1 or p.find('01')>-1) and p.find('H2')==-1:
        comTD_prc_py.append(p)
        
# Select residential T&D processes
   if p.startswith('RSD') and (p.find('00')>-1 or p.find('01')) and p.find('H2')==-1:
        rsdTD_prc_py.append(p)
        
# Select agricultural T&D processes
   if p.startswith('AGR') and (p.find('00')>-1 or p.find('01')) and p.find('H2')==-1:
        agrTD_prc_py.append(p)
        
# Select transport T&D processes
   if (p.startswith('BL') or p.startswith('TRAELC') or p.startswith('TRABGS') or p.startswith('TRAGAS') or p.startswith('TRAHFO') or p.startswith('TRALPG')) and p.find('H2')==-1:
        traTD_prc_py.append(p)

# Select transport cars
   if p.startswith('TRA_Car_Lpg_'):
        tra_carlpg_py.append(p)
   if p.startswith('TRA_Car_Gas_'):
        tra_cargsl_py.append(p)
   if p.startswith('TRA_Car_Elc_') or p.startswith('TRA_Car_Ele_') or p.startswith('TRA_Car_PIH_'):
        tra_carelc_py.append(p)
   if p.startswith('TRA_Car_Cng_'):
        tra_carcng_py.append(p)
   if p.startswith('TRA_Car_Dis_'):
        tra_cardsl_py.append(p)       
   if p.startswith('TRA_Car_GH2_') or p.startswith('TRA_Car_LH2_'):
        tra_carhh2_py.append(p)  

# Select transport lcv
   if p.startswith('TRA_Lcv_Cng'):
        tra_lcvcng_py.append(p)
   if p.startswith('TRA_Lcv_Dis'):
        tra_lcvdsl_py.append(p)
   if p.startswith('TRA_Lcv_Elc'):
        tra_lcvelc_py.append(p)
   if p.startswith('TRA_Lcv_Gas'):
        tra_lcvgas_py.append(p)
   if p.startswith('TRA_Lcv_GH2') or p.startswith('TRA_Lcv_LH2'):
        tra_lcvhh2_py.append(p)
   if p.startswith('TRA_Lcv_Lpg'):
        tra_lcvlpg_py.append(p)
   if p.startswith('TRA_Hdt_Cng'):
        tra_hdtcng_py.append(p)
   if p.startswith('TRA_Hdt_Dis'):
        tra_hdtdsl_py.append(p)
   if p.startswith('TRA_Hdt_Elc'):
        tra_hdtelc_py.append(p)
   if p.startswith('TRA_Hdt_GH2'):
        tra_hdthh2_py.append(p)

# "Export" to GAMS the modified sets 
gams.set('pri_prc',pri_prc)
gams.set('nimp_prc',nimp_prc)
gams.set('nimp_end_eu_prc',nimp_end_eu_prc)
gams.set('dhprd_prc_py',dhprd_prc_py)
gams.set('dhprc_elc_py',dhprc_elc_py)
gams.set('rsd_dh_prc_py',rsd_dh_prc_py)
gams.set('com_dh_prc_py',com_dh_prc_py)
gams.set('hpprd_prc_py',hpprd_prc_py)
gams.set('elc_nres_sc_py',elc_nres_sc_py)
gams.set('elc_nres_sh_py',elc_nres_sh_py)
gams.set('elc_nres_wh_py',elc_nres_wh_py)
gams.set('synprd_prc_py',synprd_prc_py)
gams.set ('synprd_prc_py', synprd_prc_py)
gams.set ('synblq_prc_py', synblq_prc_py)
gams.set ('synbgs_prc_py', synbgs_prc_py)
gams.set ('synflq_prc_py', synflq_prc_py)
gams.set ('synfgs_prc_py', synfgs_prc_py)
gams.set ('synelq_prc_py', synelq_prc_py)
gams.set ('synegs_prc_py', synegs_prc_py)
gams.set ('iis_ind_py', iis_ind_py)
gams.set ('inf_ind_py', inf_ind_py)
gams.set ('ich_ind_py', ich_ind_py)
gams.set ('ipp_ind_py', ipp_ind_py)
gams.set ('inm_ind_py', inm_ind_py)
gams.set ('ioi_ind_py', ioi_ind_py)
gams.set ('nen_py', nen_py)
gams.set ('iot_prc_py', iot_prc_py)
gams.set ('bioe_prc_py', bioe_prc_py)
gams.set ('bioe_ccs_prc_py', bioe_ccs_prc_py)
gams.set ('synegrgs_prc_py', synegrgs_prc_py)
gams.set ('synegrlq_prc_py', synegrlq_prc_py)
gams.set ('eleTD_prc_py', eleTD_prc_py)
gams.set ('h2TD_prc_py', h2TD_prc_py)
gams.set ('indTD_prc_py', indTD_prc_py)
gams.set ('comTD_prc_py', comTD_prc_py)
gams.set ('rsdTD_prc_py', rsdTD_prc_py)
gams.set ('agrTD_prc_py', agrTD_prc_py)
gams.set ('traTD_prc_py', traTD_prc_py)
gams.set('tra_carlpg_py',tra_carlpg_py)
gams.set('tra_cargsl_py',tra_cargsl_py)
gams.set('tra_carelc_py',tra_carelc_py)
gams.set('tra_carcng_py',tra_carcng_py)
gams.set('tra_cardsl_py',tra_cardsl_py)
gams.set('tra_carhh2_py',tra_carhh2_py)
gams.set('tra_lcvcng_py',tra_lcvcng_py)
gams.set('tra_lcvdsl_py',tra_lcvdsl_py)
gams.set('tra_lcvelc_py',tra_lcvelc_py)
gams.set('tra_lcvgas_py',tra_lcvgas_py)
gams.set('tra_lcvhh2_py',tra_lcvhh2_py)
gams.set('tra_lcvlpg_py',tra_lcvlpg_py)
gams.set('tra_hdtcng_py',tra_hdtcng_py)
gams.set('tra_hdtdsl_py',tra_hdtdsl_py)
gams.set('tra_hdtelc_py',tra_hdtelc_py)
gams.set('tra_hdthh2_py',tra_hdthh2_py)

endEmbeddedCode pri_prc, nimp_prc,nimp_end_eu_prc,dhprd_prc_py,dhprc_elc_py,rsd_dh_prc_py,com_dh_prc_py,hpprd_prc_py,elc_nres_sc_py,elc_nres_sh_py,elc_nres_wh_py,synprd_prc_py, synblq_prc_py, synbgs_prc_py,synflq_prc_py,synfgs_prc_py,synelq_prc_py,synegs_prc_py,iis_ind_py,inf_ind_py,ich_ind_py,ipp_ind_py,inm_ind_py,ioi_ind_py,nen_py,iot_prc_py,bioe_prc_py,bioe_ccs_prc_py,synegrgs_prc_py,synegrlq_prc_py,eleTD_prc_py,h2TD_prc_py,indTD_prc_py,comTD_prc_py,rsdTD_prc_py,agrTD_prc_py,traTD_prc_py,tra_carlpg_py,tra_cargsl_py,tra_carelc_py,tra_carcng_py,tra_cardsl_py,tra_carhh2_py,tra_lcvcng_py,tra_lcvdsl_py,tra_lcvelc_py,tra_lcvgas_py,tra_lcvhh2_py,tra_lcvlpg_py,tra_hdtcng_py,tra_hdtdsl_py,tra_hdtelc_py,tra_hdthh2_py






*************************************
*** TABLE DOMESTIC PRIMARY PRODUCTION
*************************************

sets

* reserve and production commodities
    cohcol_rsv(commodity) coal and lignite reserve commodities /COHRSV,COLRSV/
    oil_rsv(commodity) oil reserves commodities /OILRSV/
    gas_rsv(commodity) gas reserves commodities /GASRSV/
    hyd_rsv(commodity) hydro production commodities /RENHYD/
    bio_rsv(commodity) biomass production commodities /BIOCRP1,BIOCRP2,BIOGAS,BIOMUN,BIORPS,BIOSLU,BIOWOO/
    win_rsv(commodity) wind production commodities /RENWIN/
    sol_rsv(commodity) solar production commodities /RENSOL/
    envheat_rsv(commodity) environmental heat production commodities /RENAHT,RENGHT/
    geo_oce_rsv(commodity) geothermal ocean and others production commodities /ELCTID,ELCWAV,RENGEO/
    
* reserve and production processes
    coa_prod(Process) coal and lignite primary production
    oil_prod(Process) oil primary production
    gas_prod(Process) gas primary production 
    hyd_prod(Process) hydro primary production 
    bio_prod(Process) biomass and biofuels primary production 
    win_prod(Process) wind  primary production
    sol_prod(Process) solar primary production 
    envheat_prod(Process) environmental heat primary production 
    geo_oce_prod(Process) geothermal ocean and others primary production
    
* mapping to create the primary production table 
    prod_prc_fuel(Process, fuel) process to fuel mapping for creating the primary production table 

parameter
    out_pprod(rpt_reg,fuel,rt) primary production table
;

* select the processes     
coa_prod(pri_prc)=yes$sum((cohcol_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",cohcol_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
oil_prod(pri_prc)=yes$sum((oil_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",oil_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
gas_prod(pri_prc)=yes$sum((gas_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",gas_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
hyd_prod(pri_prc)=yes$sum((hyd_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hyd_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
bio_prod(pri_prc)=yes$sum((bio_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",bio_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
win_prod(pri_prc)=yes$sum((win_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",win_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
sol_prod(pri_prc)=yes$sum((sol_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",sol_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
envheat_prod(pri_prc)=yes$sum((envheat_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",envheat_rsv,pri_prc,rt,region,v,ts,user_constraint),1);
geo_oce_prod(pri_prc)=yes$sum((geo_oce_rsv,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",geo_oce_rsv,pri_prc,rt,region,v,ts,user_constraint),1);

* map processes to the rows of the table 
prod_prc_fuel(coa_prod,"coal")=yes;
prod_prc_fuel(oil_prod,"oil")=yes;
prod_prc_fuel(gas_prod,"gas")=yes;
prod_prc_fuel(hyd_prod,"hydro")=yes;
prod_prc_fuel(bio_prod,"biomass")=yes;
prod_prc_fuel(win_prod,"wind")=yes;
prod_prc_fuel(sol_prod,"solar")=yes;
prod_prc_fuel(envheat_prod,"env_heat")=yes;
prod_prc_fuel(geo_oce_prod,"geo_oce")=yes;


* extract the results 
out_pprod(rpt_reg,"biomass",rt)  =  sum(region$sameas(region, rpt_reg), sum((v,ts,user_constraint),sum(pri_prc$prod_prc_fuel(pri_prc,"biomass"),veda_vdd("var_act","-",pri_prc,rt,region,v,ts,user_constraint))));
out_pprod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg),out_pprod(rpt_reg,fuel,rt)); 

display out_pprod;

*************************************
*** TABLE NET IMPORTS (var_fin is exports, var_fout is imports, var_fout-var_fin is net imports)
*************************************

sets

* import and export commodities 
    nimp_coa(Commodity) coal traded commodities /COACOK,COAHAR,COALIG,COABRO/
    nimp_oil(Commodity) oil traded commodities /OILGSL, OILHFO, OILNAP, OILOTH, OILCRD, OILDST, OILFDS, OILKER, OILLPG, OILNEU, OILRFG/
    nimp_gas(Commodity) natrural gas traded commodities /GASNAT, GASLNG/
    nimp_bio(Commodity) biomass and biofuels traded commodities /BIOLIQ,BIOWOO,BIOEMHV,BIOETHA,BIOOILFS,BIOHVO,BIOSUGFS/
    nimp_elc(Commodity) electricity traded commodities /ELCHIG, GN1/
    nimp_h2(Commodity) hydrogen traded commodities /SYNH2CU, SYNH2CT, SYNH2DT,SYNGH2CT,SYNGH2CU,SYNGH2DT,IMPLH2/
    nimp_e_fuels(Commodity) e-fuels commodities /ISYNG,SYNGDST,SYNGGSL,SYNGKER,SYNGLPG,SYNGNAP,SYNGOTH/
    nimp_e_gases(Commodity) e-gases commodities /ISYNGGAS/
    nimp_co2(commodity) Co2 commodities involved in the trade /TOTCO2/
    
* import and export processes 
    nimp_coa_prc(Process) coal import and export processes
    nimp_oil_prc(Process) oil import and export processes 
    nimp_gas_prc(Process) natural gas import and export processes
    nimp_bio_prc(Process) biomass and biofuels import and export processes
    nimp_elc_prc(Process) electricity import and export processes
    nimp_h2_prc(Process) hydrogen import and export processes
    nimp_e_fuels_prc(Process) e-fuels import and export processes 
    nimp_e_gases_prc(Process)
   
* mapping to create the primary production table     
    nimp_prc_fuel(Process,Fuel)
*    nimp_prc_fuel(process,fuel) /#coa_nimp.coal, #oil_nimp.oil, #gas_nimp.gas, #bio_nimp.biomass, #elc_nimp.elec, #h2_nimp.h2/
    cf_nimp(process) processes needed activity unit conversion /EXPEMHV,IMPBIOEMHV,IMPBIOHVO,IMPBIOETH,IMPBIOOIL/
;

nimp_coa_prc(nimp_prc)=yes$sum((nimp_coa, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_coa,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_coa,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_oil_prc(nimp_prc)=yes$sum((nimp_oil, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_oil,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_oil,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_gas_prc(nimp_prc)=yes$sum((nimp_gas, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_gas,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_gas,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_bio_prc(nimp_prc)=yes$sum((nimp_bio, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_bio,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_bio,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_elc_prc(nimp_prc)=yes$sum((nimp_elc, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_elc,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_elc,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_h2_prc(nimp_prc)=yes$sum((nimp_h2, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_h2,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_h2,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_e_fuels_prc(nimp_prc)=yes$sum((nimp_e_fuels, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_e_fuels,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_e_fuels,nimp_prc,rt,region,v,ts,user_constraint)), 1);
nimp_e_gases_prc(nimp_prc)=yes$sum((nimp_e_gases, rt, region,v,ts,user_constraint)$(veda_vdd("var_fout",nimp_e_gases,nimp_prc,rt,region,v,ts,user_constraint) or veda_vdd("var_fin",nimp_e_gases,nimp_prc,rt,region,v,ts,user_constraint)), 1);

nimp_prc_fuel(nimp_prc,"coal")=yes$nimp_coa_prc(nimp_prc);nimp_prc_fuel(nimp_prc,"oil")=yes$nimp_oil_prc(nimp_prc);nimp_prc_fuel(nimp_prc,"gas")=yes$nimp_gas_prc(nimp_prc); 
nimp_prc_fuel(nimp_prc,"biomass")=yes$nimp_bio_prc(nimp_prc);nimp_prc_fuel(nimp_prc,"elec")=yes$nimp_elc_prc(nimp_prc);nimp_prc_fuel(nimp_prc,"h2")=yes$nimp_h2_prc(nimp_prc);
nimp_prc_fuel(nimp_prc,"efuels")=yes$nimp_e_fuels_prc(nimp_prc);
nimp_prc_fuel(nimp_prc,"egases")=yes$nimp_e_gases_prc(nimp_prc);

cf("EXPEMHV")=0.0374;cf("IMPBIOEMHV")=0.0374;cf("IMPBIOHVO")=0.044;cf("IMPBIOOIL")=0.044;cf("IMPBIOETH")=0.0268;cf("IMPBIOETH")=0.0268;CF("IMPBIOSUGFS")=0.0268;
cf("IMPBIOSUGFS")=1/12.6582278481013;

parameter
    out_nimp(rpt_reg,fuel,rt) net imports table
    out_nimp_prc(rpt_reg,process,fuel,rt) net imports by import process or corridor and fuel (internal parameter)
    out_nimp_no_endog(rpt_reg,fuel,rt) net imports excluding endogenous trade
;    

out_nimp(rpt_reg,fuel,rt)  = sum((commodity,process,region,v,ts,user_constraint)$(sameas(region, rpt_reg) $(not nimp_co2(commodity)) $nimp_prc_fuel(process,fuel) $(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)+veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint))),
                                    cf(process)*(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)-veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint)));

out_nimp_prc(rpt_reg,process,fuel,rt) = sum((commodity,region,v,ts,user_constraint)$(sameas(region, rpt_reg) $(not nimp_co2(commodity)) $nimp_prc_fuel(process,fuel) $(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)+veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint))),
                                    cf(process)*(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)-veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint)));


* Net imports for the EU (considering only import and export processes outside of the EU-27 borders)

out_nimp("EU-27",fuel,rt) =sum(rpt_reg$eu27(rpt_reg),

sum((commodity,process,region,v,ts,user_constraint)$(sameas(region, rpt_reg) $nimp_prc_fuel(process,fuel) $(not nimp_co2(commodity)) $(not nimp_end_eu_prc(process)) $(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)+veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint))),
                                    cf(process)*(veda_vdd("var_fout",commodity,process,rt,region,v,ts,user_constraint)-veda_vdd("var_fin",commodity,process,rt,region,v,ts,user_constraint)))

);

*************************************
*** TABLE ELECTRICITY PRODUCTION
*************************************


sets
* electricity production processes
    eprd_prc (Process) electricity production processes (all - with and without CCS)
    eprd_ccs_prc(Process) electricity production processes with CCS

* commodities for electricity and fuels used for electricity production 
    eprd_elc(Commodity) electricity production commodities /ELCHIG,ELCHIGG,ELCMED,ELCLOW,AGRELC,COMELC,INDELC,RSDELC,TRAELC,TRAELC_EV,TRAELC_V2G/

* fuels used as input to electricity production
    eprd_coa(Commodity) coal to electricity generation /ELCCOH, ELCCOL, INDCOA, INDCOB, INDCOL/
    eprd_ngas(Commodity) natural gas to electricity generation /ELCGAS,INDGAS,AGRGAS,COMGAS,RSDGAS/
    eprd_bgas(Commodity) biogas to electricity generation /ELCBGS, INDBGS, COMBGS, RSDBGS/
    eprd_gas(Commodity) natural derived and biogases to electricity generation /#eprd_ngas,#eprd_bgas,INDCOG,INDBFG,SUPGAS, ELCBFG,ELCBFT,ELCCOG,ELCCOP,ELCIIS/
    eprd_h2(Commodity) hydrogen to electricity generation /SYNH2CT,SYNH2CU,SYNH2DT,RSDHH2,RSDGHH2,INDHH2,INDGHH2,COMHH2,COMGHH2,SYNGH2CT,SYNGH2CU,SYNGH2DT/
    eprd_dsl(Commodity) oil to electricity generation /ELCDST,ELCHFO,INDHFO,INDLFO,INDNAP,INDRFG,RSDOIL,RSDLPG,INDLPG,AGRLPG,COMLPG/
    eprd_bdl(Commodity) biodiesel to electricity generation /ELCBDL,RSDBDL,COMBDL,AGRBDL/
    eprd_oil(Commodity) oil and biodiesel to electricity generation /#eprd_dsl,#eprd_bdl/
    eprd_nuc(Commodity) nuclear to electricity generation /ELCNUC, ELCNUCA,NUCH2/
    eprd_bio(Commodity) wood and wastes to electricity generation /INDBIO,INDBLQ,INDMUN,INDSLU,ELCMUN,ELCWOO,ELCSLU /
    eprd_hyd(Commodity) hydro to electricity generation /ELCHYD/
    eprd_wnd(Commodity) wind to electricity generation /ELCWIN/
    eprd_sol(Commodity) solar to electricity generation /ELCSOL, INDSOL, RSDSOL, COMSOL, AGRSOL/
    eprd_oth(Commodity) other fuels to electricity generation /ELCGEO,ELCTID,ELCWAV,ELCAHT/
    eprd_all(Commodity) all commodites used to fuel electricity generation processes /#eprd_coa, #eprd_gas, #eprd_h2, #eprd_dsl, #eprd_bdl, #eprd_nuc, #eprd_bio, #eprd_hyd, #eprd_wnd, #eprd_sol, #eprd_oth/

* Create the rows of the table in the template file 
    eprd_prc_fuels(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the rows of the table)
    /#eprd_coa.(coal,coal_ccs), #eprd_gas.(gas, gas_ccs), #eprd_oil.(oil,oil_ccs), #eprd_nuc.nuclear, #eprd_bio.(biomass,biomass_ccs), #eprd_hyd.hydro, #eprd_wnd.wind, #eprd_sol.solar, #eprd_h2.h2, #eprd_oth.geo_oce/ 

    eprd_prc_fuels_in(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the fuel consumption )
    /#eprd_coa.coal, #eprd_gas.gas, #eprd_oil.oil, #eprd_nuc.nuclear, #eprd_bio.biomass, #eprd_hyd.hydro, #eprd_wnd.wind, #eprd_sol.solar, #eprd_h2.h2, #eprd_oth.geo_oce/ 
   
    elc_prc(region, process, fuel, rt) set including all processes identified as electricity generation technologies per region and time period (used for debug purposes)
    eprd_prccap_fuels(Process,fuel)

;

parameter
    out_elprod(rpt_reg,fuel,rt) electricity production by fuel table
    in_elprod(rpt_reg,fuel,rt) consumption by fuel for electricity production
    elc_prc_prod(region, process, fuel, rt) production by process and fuel 
;    

* Select processes that produce electricity and consume at least one of the identified fuels for electricity production
eprd_prc(process) = sum((eprd_elc,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",eprd_elc,process,rt,region,v,ts,user_constraint),1)*sum((eprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",eprd_all,process,rt,region,v,ts,user_constraint), 1);
eprd_prc(bioe_prc_py)=yes;

eprd_ccs_prc(eprd_prc) = sum((CO2_ccs,rt, region,v,ts,user_constraint)$veda_vdd("var_fout",CO2_ccs,eprd_prc,rt,region,v,ts,user_constraint),1);
eprd_ccs_prc(bioe_ccs_prc_py) = yes;


* Calculate fuel consumption by electricity production process (total and by fuel)
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;
aux_all(eprd_prc,rt,region) = sum((eprd_all,v,ts,user_constraint)$veda_vdd("var_fin",eprd_all,eprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",eprd_all,eprd_prc,rt,region,v,ts,user_constraint));
aux_com(commodity,eprd_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",commodity,eprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",commodity,eprd_prc,rt,region,v,ts,user_constraint));

* Calculate production for electricity production processes with and without CCS
out_elprod(rpt_reg,fuel,rt)$(not ccs_fuels(fuel)) = sum((eprd_prc,eprd_elc,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $eprd_prc_fuels(commodity,fuel) $aux_com(commodity,eprd_prc,rt,region) $aux_all(eprd_prc,rt,region) $veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint) $(not eprd_ccs_prc(eprd_prc))),
                             veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,eprd_prc,rt,region)/aux_all(eprd_prc,rt,region));                                
out_elprod(rpt_reg,fuel,rt)$ccs_fuels(fuel) = sum((eprd_ccs_prc,eprd_elc,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $eprd_prc_fuels(commodity,fuel) $aux_com(commodity,eprd_ccs_prc,rt,region) $aux_all(eprd_ccs_prc,rt,region) $veda_vdd("var_fout",eprd_elc,eprd_ccs_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",eprd_elc,eprd_ccs_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,eprd_ccs_prc,rt,region)/aux_all(eprd_ccs_prc,rt,region));                                
out_elprod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), out_elprod(rpt_reg,fuel,rt)); 


eprd_prccap_fuels(eprd_prc,fuel) = yes$sum((rt,region,eprd_elc,commodity,v,ts,user_constraint)$(eprd_prc_fuels(commodity,fuel) $aux_com(commodity,eprd_prc,rt,region) $aux_all(eprd_prc,rt,region) $veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint)),1);

* Calculate fuel consumption for electricity production processes with and without CCS
in_elprod(rpt_reg,fuel,rt) = sum((region,commodity,eprd_prc)$(sameas(region,rpt_reg) $eprd_prc_fuels_in(commodity,fuel)), aux_com(commodity,eprd_prc,rt,region));
in_elprod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), in_elprod(rpt_reg,fuel,rt)); 


* enable the following comment to get (for debug purposes) a list of all processes identified as electricity generation technologies
elc_prc(region, process, fuel, rt) = sum((eprd_elc,v,ts,user_constraint)$veda_vdd("var_fout",eprd_elc,process,rt,region,v,ts,user_constraint),1)*sum((eprd_all,v,ts,user_constraint)$(eprd_prc_fuels_in(eprd_all,fuel) $veda_vdd("var_fin",eprd_all,process,rt,region,v,ts,user_constraint)), 1);
elc_prc_prod(region, process, fuel, rt)$elc_prc(region, process, fuel, rt) = sum((eprd_elc,v,ts,user_constraint)$veda_vdd("var_fout",eprd_elc,process,rt,region,v,ts,user_constraint),veda_vdd("var_fout",eprd_elc,process,rt,region,v,ts,user_constraint));

parameter
    out_elprod_prc(rpt_reg,process,fuel,rt) electrcicity production by process and fuel (internal parameter)
;

out_elprod_prc(rpt_reg,eprd_prc,fuel,rt)$(not ccs_fuels(fuel)) = sum((eprd_elc,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $eprd_prc_fuels(commodity,fuel) $aux_com(commodity,eprd_prc,rt,region) $aux_all(eprd_prc,rt,region) $veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint) $(not eprd_ccs_prc(eprd_prc))),
                             veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,eprd_prc,rt,region)/aux_all(eprd_prc,rt,region));                                

out_elprod_prc(rpt_reg,eprd_prc,fuel,rt)$(ccs_fuels(fuel)) = sum((eprd_elc,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $eprd_prc_fuels(commodity,fuel) $aux_com(commodity,eprd_prc,rt,region) $aux_all(eprd_prc,rt,region) $veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint) $(eprd_ccs_prc(eprd_prc))),
                             veda_vdd("var_fout",eprd_elc,eprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,eprd_prc,rt,region)/aux_all(eprd_prc,rt,region));                                

*************************************
*** TABLE HYDROGEN PRODUCTION
*************************************
sets
* hydrogen production processes 
    h2prd_prc(process) hydrogen production processes (all - with and without CCS)
    h2prd_ccs_prc(Process) hydrogen production processes with CCS    

* commodities for hydrogen and fuels used for hydrogen production 
    h2prd_h2(Commodity) hydrogen production commodities / SYNH2CT,SYNH2CU,SYNH2DT,SYNGH2CT,SYNGH2CU,SYNGH2DT/

* fuels used as input to hydrogen production
    h2prd_coa(Commodity) coal to hydrogen production /COAHAR/
    h2prd_ngas(Commodity) natural gas to hydrogen production /GASNAT/
    h2prd_bgas(Commodity) biogas to hydrogen production /BIOGAS/
    h2prd_gas(Commodity) natural gas and biogases to hydrogen production /#h2prd_ngas,#h2prd_bgas/
    h2prd_elc(Commodity) electricity to hydrogen production  /ELCHIG, ELCHIGG, ELCMED, ELCLOW /
    h2prd_dsl(Commodity) oil to electricity production /OILHFO/
    h2prd_bdl(Commodity) biodiesel to hydrogen production /BIOLIQ,BIOETHA/
    h2prd_oil(Commodity) oil and biodiesel to hydrogen production /#h2prd_dsl,#h2prd_bdl/
    h2prd_nuc(Commodity) nuclear to hydrogen production /NUCH2/
    h2prd_bio(Commodity) wood and wastes to hydrogen production /BIOWOO/
    h2prd_oth(Commodity) other fuels to hydrogen production /ELCSOL/
    H2prd_all(Commodity) all commodites used to fuel hydrogen production processes /#h2prd_coa, #h2prd_ngas, #h2prd_bgas, #h2prd_elc, #h2prd_dsl, #h2prd_bdl, #h2prd_nuc, #h2prd_bio, #h2prd_oth/
   
* Create the rows of the table in the template file 
    h2prd_prc_fuels(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the rows of the table)
    /#h2prd_coa.(coal,coal_ccs), #h2prd_gas.(gas, gas_ccs), #h2prd_oil.(oil,oil_ccs), #h2prd_nuc.nuclear, #h2prd_bio.(biomass,biomass_ccs), #h2prd_elc.elec, #h2prd_oth.other/    

    h2prd_prc_fuels_in(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the fuel consumption )
    /#h2prd_coa.coal, #h2prd_gas.gas, #h2prd_oil.oil, #h2prd_nuc.nuclear, #h2prd_bio.biomass, #h2prd_elc.elec, #h2prd_oth.other/    

;

parameter
    out_h2prod(rpt_reg,fuel,rt) hydrogen production by fuel table
    in_h2prod(rpt_reg,fuel,rt) consumption by fuel for hydrogen production
    out_h2prod_prc(rpt_reg,process,fuel,rt) hydrogen production by process and fuel internal table
    aux_h2_elc(commodity,process,rt,region)
    h2elc(region,fuel,rt)
    out_h2elc(region,fuel,rt) 
;

* Select processes that produce hydrogen and consume at least one of the identified fuels for hydrogen production
h2prd_prc(process) = sum((h2prd_h2,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",h2prd_h2,process,rt,region,v,ts,user_constraint),1)*sum((h2prd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",h2prd_all,process,rt,region,v,ts,user_constraint), 1);
h2prd_ccs_prc(h2prd_prc) = sum((CO2_ccs,rt, region,v,ts,user_constraint)$veda_vdd("var_fout",CO2_ccs,h2prd_prc,rt,region,v,ts,user_constraint),1);

* Calculate fuel consumption by hydrogen  production process (total and by fuel)
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;
aux_h2_elc(commodity,process,rt,region)=0;
aux_all(h2prd_prc,rt,region) = sum((H2prd_all,v,ts,user_constraint)$veda_vdd("var_fin",H2prd_all,h2prd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",h2prd_all,h2prd_prc,rt,region,v,ts,user_constraint));
*aux_com(commodity,h2prd_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",commodity,h2prd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",commodity,h2prd_prc,rt,region,v,ts,user_constraint));
aux_h2_elc(h2prd_elc,h2prd_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",h2prd_elc,h2prd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",h2prd_elc,h2prd_prc,rt,region,v,ts,user_constraint));
h2elc(region,"elec",rt)=sum((h2prd_elc,h2prd_prc),aux_h2_elc(h2prd_elc,h2prd_prc,rt,region));
out_h2elc(region,"elec",rt)=h2elc(region,"elec",rt)

display aux_h2_elc;

* Calculate production for hydrogen production processes with and without CCS
out_h2prod(rpt_reg,fuel,rt)$(not ccs_fuels(fuel)) = sum((h2prd_prc,h2prd_h2,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $(not (h2prd_ccs_prc(h2prd_prc))) $h2prd_prc_fuels(commodity,fuel) $aux_com(commodity,h2prd_prc,rt,region) $aux_all(h2prd_prc,rt,region) $veda_vdd("var_fout",h2prd_h2,h2prd_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",h2prd_H2,h2prd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,h2prd_prc,rt,region)/aux_all(h2prd_prc,rt,region));                                

out_h2prod(rpt_reg,fuel,rt)$ccs_fuels(fuel) = sum((h2prd_ccs_prc,h2prd_h2,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $h2prd_prc_fuels(commodity,fuel) $aux_com(commodity,h2prd_ccs_prc,rt,region) $aux_all(h2prd_ccs_prc,rt,region) $veda_vdd("var_fout",h2prd_h2,h2prd_ccs_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",h2prd_H2,h2prd_ccs_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,h2prd_ccs_prc,rt,region)/aux_all(h2prd_ccs_prc,rt,region));                                
out_h2prod("EU-27",fuel,rt) = eps+sum(rpt_reg$eu27(rpt_reg),out_h2prod(rpt_reg,fuel,rt)); 

out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt)$(not ccs_fuels(fuel)) = sum((h2prd_h2,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $(not h2prd_ccs_prc(h2prd_prc)) $h2prd_prc_fuels(commodity,fuel) $aux_com(commodity,h2prd_prc,rt,region) $aux_all(h2prd_prc,rt,region) $veda_vdd("var_fout",h2prd_h2,h2prd_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",h2prd_H2,h2prd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,h2prd_prc,rt,region)/aux_all(h2prd_prc,rt,region));                                

out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt)$(ccs_fuels(fuel)) = sum((h2prd_h2,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $( h2prd_ccs_prc(h2prd_prc)) $h2prd_prc_fuels(commodity,fuel) $aux_com(commodity,h2prd_prc,rt,region) $aux_all(h2prd_prc,rt,region) $veda_vdd("var_fout",h2prd_h2,h2prd_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",h2prd_H2,h2prd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,h2prd_prc,rt,region)/aux_all(h2prd_prc,rt,region));                                

* Calculate fuel consumption for hydrogen production processes with and without CCS
in_h2prod(rpt_reg,fuel,rt) = sum((region,commodity,h2prd_prc)$(sameas(region,rpt_reg) $h2prd_prc_fuels_in(commodity,fuel)), eps+aux_com(commodity,h2prd_prc,rt,region));
in_h2prod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), in_h2prod(rpt_reg,fuel,rt)); 



*************************************
*** TABLE DISTRICT HEATING SUPPLY
*************************************
sets
* distict heating production processes (all)
    dhprd_prc(Process) district heating production processes (all - with and without CCS)
    dhprc_elc(Process) district heating production processes that are electric heat pumps 
    dhprd_ccs_prc(Process) district heating production processes with CCS
    dhprd_aut_prc(Process) district heating production process (on-site CHP plants)
    hpprd_prc(Process) heatpump technologies
        
* commodities for distirct heating and fuels used for district heating production 
    dhprd_ah(Commodity) heating production from on-site CHP plants /ICHHTH,ICLHTH,ICUHTH,IISHTH,INDHTH,INFHTH,INMHTH,IOIHTH,IPPHTH,REFHTH,COMHET,RSDHET,AGRHET,AGR_Low_Ent_Het,AGR_Spe_Het_Use,NR_ES-HO-SpHeat,NR_ES-HO-WatHeat,NR_ES-HR-SpHeat,NR_ES-HR-WatHeat,NR_ES-OF-SpHeat,NR_ES-OF-WatHeat,NR_ES-SL-SpHeat,NR_ES-SL-WatHeat,NR_ES-SR-SpHeat,NR_ES-SR-WatHeat,NR_ES-SS-SpHeat,NR_ES-SS-WatHeat,R_ES-DH-70-SpHeat,R_ES-DH-SpHeat,R_ES-DH-WatHeat,R_ES-FL-SpHeat,R_ES-FL-WatHeat,R_ES-SD-SpHeat,R_ES-SD-WatHeat/    
*    dhprd_dh(Commodity) heating production commodities (district heating and onsite) /HETHTH,SUPHTH, #dhprd_ah/
    dhprd_dhind(Commodity) district heating production commodity including also marketed industrial heat /HETHTH,INDHTH/
    dhprd_dh(Commodity) strictly district heating /HETHTH/
    
* fuels used as input to district heating production
    dhprd_coa(Commodity) coal to district heating generation /#eprd_coa,COAHAR/
    dhprd_ngas(Commodity) natural gas to district heating generation /#eprd_ngas/
    dhprd_bgas(Commodity) biogas to district heating generation /#eprd_bgas/
    dhprd_gas(Commodity) natural derived and biogases to districth heating generation /#eprd_gas/
    dhprd_h2(Commodity) hydrogen to district heating generation /#eprd_h2/
    dhprd_dsl(Commodity) oil to district heating generation /#eprd_dsl/
    dhprd_bdl(Commodity) biodiesel to district heating generation /#eprd_bdl/
    dhprd_oil(Commodity) oil and biodiesel to district heating generation /#eprd_dsl,#eprd_bdl/
    dhprd_nuc(Commodity) nuclear to district heating generation /#eprd_nuc/
    dhprd_bio(Commodity) wood and wastes to district heating generation /#eprd_bio,BIOWOO/
    dhprd_hyd(Commodity) hydro to district heating generation /#eprd_hyd/
    dhprd_wnd(Commodity) wind to district heating generation /#eprd_wnd/
    dhprd_sol(Commodity) solar to district heating generation /#eprd_sol/
    dhprd_elc(Commodity) electricity to district heating generation /#eprd_elc/
    hpprd_elc(Commodity) /#eprd_elc/
    dhprd_oth(Commodity) other fuels to distric heatinggeneration /#eprd_oth/

    dhprd_all(Commodity) all commodites used to fuel district heating generation processes
    /#dhprd_coa, #dhprd_gas, #dhprd_h2, #dhprd_dsl, #dhprd_bdl, #dhprd_nuc, #dhprd_bio, #dhprd_hyd, #dhprd_wnd, #dhprd_sol, #dhprd_elc, #dhprd_oth/

* Create the rows of the table in the template file 
    dhprd_prc_fuels(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the rows of the table)
    /#dhprd_coa.(coal,coal_ccs), #dhprd_gas.(gas, gas_ccs), #dhprd_oil.(oil,oil_ccs), #dhprd_bio.(biomass,biomass_ccs), #dhprd_hyd.hydro, #dhprd_wnd.wind, #dhprd_sol.solar, #dhprd_h2.h2, #dhprd_elc.elec, (#dhprd_oth,#dhprd_nuc).other/ 

    dhprd_prc_fuels_in(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the fuel consumption )
    /#dhprd_coa.coal, #dhprd_gas.gas, #dhprd_oil.oil, #dhprd_nuc.nuclear, #dhprd_bio.biomass, #dhprd_hyd.hydro, #dhprd_wnd.wind, #dhprd_sol.solar, #dhprd_h2.h2, #dhprd_elc.elec, #dhprd_oth.other/ 
        
;
parameter
    out_dhprod(rpt_reg,fuel,rt) district heating production by fuel (centralised and autoproducers plants)
    out_dhprod_prc(rpt_reg,process,fuel,rt) district heating production by fuel and process (internal parameter)
    in_dhprod(rpt_reg,fuel,rt) fuel consumption for district heating (centralised and autoproducers plants)
    aux_dh(commodity,process,rt,region)
    aux_dh_all(commodity,process,rt,region)
    dh_elc(region,rt)
    dh_all(region,rt)
    share_dh(region,rt)

;    

* Select processes that produce district heating and consume at least one of the identified fuels for electricity production
*dhprd_aut_prc(dhprd_prc_py) = sum((dhprd_ah,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",dhprd_ah,dhprd_prc_py,rt,region,v,ts,user_constraint),1)*sum((dhprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc_py,rt,region,v,ts,user_constraint), 1);
dhprd_aut_prc(dhprd_prc_py) = sum((dhprd_dhind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dhind,dhprd_prc_py,rt,region,v,ts,user_constraint),1)*sum((dhprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc_py,rt,region,v,ts,user_constraint), 1);
*dhprd_prc(dhprd_prc_py) = sum((dhprd_dh,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dh,dhprd_prc_py,rt,region,v,ts,user_constraint),1)*sum((dhprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc_py,rt,region,v,ts,user_constraint), 1);
dhprd_prc(dhprd_prc_py) = sum((dhprd_dhind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dhind,dhprd_prc_py,rt,region,v,ts,user_constraint),1)*sum((dhprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc_py,rt,region,v,ts,user_constraint), 1);

*hpprd_prc(hpprd_prc_py) = sum((hpprd_dhind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dhind,dhprd_prc_py,rt,region,v,ts,user_constraint),1)*sum((dhprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc_py,rt,region,v,ts,user_constraint), 1);

dhprd_ccs_prc(dhprd_prc) = sum((CO2_ccs,rt, region,v,ts,user_constraint)$veda_vdd("var_fout",CO2_ccs,dhprd_prc,rt,region,v,ts,user_constraint),1);

* Calculate fuel consumption by district heating production process (total and by fuel)
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0; aux_dh(commodity,process,rt,region)=0;aux_dh_all(commodity,process,rt,region)=0;
aux_all(dhprd_prc,rt,region) = sum((dhprd_all,v,ts,user_constraint)$veda_vdd("var_fin",dhprd_all,dhprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",dhprd_all,dhprd_prc,rt,region,v,ts,user_constraint));
aux_com(commodity,dhprd_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",commodity,dhprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",commodity,dhprd_prc,rt,region,v,ts,user_constraint));

aux_dh(dhprd_dh,dhprd_prc,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint));

display aux_dh;
dh_elc(region,rt)=sum((commodity,dhprc_elc_py),aux_dh(commodity,dhprc_elc_py,rt,region)$(dhprd_dh(commodity)));
display dh_elc;
*dh_non_elc(region,rt)
dh_all(region,rt)=sum((commodity,dhprd_prc),aux_dh(commodity,dhprd_prc,rt,region)$(dhprd_dh(commodity)));
display dh_all;

share_dh(region,rt)= dh_elc(region,rt)/dh_all(region,rt)$(dh_elc(region,rt)<>0);
share_dh(region,rt)$(not (share_dh(region,rt) = share_dh(region,rt))) = eps;
display share_dh;

* Calculate production for distrcit heating processes with and without CCS
*out_dhprod(rpt_reg,fuel,rt)$(not ccs_fuels(fuel)) = sum((dhprd_prc,dhprd_dh,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint) $(not dhprd_ccs_prc(dhprd_prc))),
*                             veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_prc,rt,region)/aux_all(dhprd_prc,rt,region));                                
out_dhprod(rpt_reg,fuel,rt)$(not ccs_fuels(fuel)) = sum((dhprd_prc,dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint) $(not dhprd_ccs_prc(dhprd_prc))),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_prc,rt,region)/aux_all(dhprd_prc,rt,region));                                

*out_dhprod(rpt_reg,fuel,rt)$ccs_fuels(fuel) = sum((dhprd_ccs_prc,dhprd_dh,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_ccs_prc,rt,region) $aux_all(dhprd_ccs_prc,rt,region) $veda_vdd("var_fout",dhprd_dh,dhprd_ccs_prc,rt,region,v,ts,user_constraint)),
*                             veda_vdd("var_fout",dhprd_dh,dhprd_ccs_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_ccs_prc,rt,region)/aux_all(dhprd_ccs_prc,rt,region));                                

out_dhprod(rpt_reg,fuel,rt)$ccs_fuels(fuel) = sum((dhprd_ccs_prc,dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_ccs_prc,rt,region) $aux_all(dhprd_ccs_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_ccs_prc,rt,region,v,ts,user_constraint)),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_ccs_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_ccs_prc,rt,region)/aux_all(dhprd_ccs_prc,rt,region));                                

out_dhprod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), out_dhprod(rpt_reg,fuel,rt));

out_dhprod_prc(rpt_reg,dhprd_prc,fuel,rt)$(not ccs_fuels(fuel)) = sum((dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)$(not dhprd_ccs_prc(dhprd_prc))),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_prc,rt,region)/aux_all(dhprd_prc,rt,region));                                

out_dhprod_prc(rpt_reg,dhprd_prc,fuel,rt)$(ccs_fuels(fuel)) = sum((dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)$( dhprd_ccs_prc(dhprd_prc))),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_prc,rt,region)/aux_all(dhprd_prc,rt,region));                                

* Calculate fuel consumption for district heating production processes with and without CCS
in_dhprod(rpt_reg,fuel,rt) = sum((region,commodity,dhprd_prc)$(sameas(region,rpt_reg) $dhprd_prc_fuels_in(commodity,fuel)), aux_com(commodity,dhprd_prc,rt,region));
in_dhprod("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), in_dhprod(rpt_reg,fuel,rt)); 

parameter
    out_dhprod_prc(rpt_reg,process,fuel,rt)
     out_dhprod_prc2(rpt_reg,process,fuel,rt)
     out_share_dh(region,rt);
    
out_dhprod_prc(rpt_reg,dhprd_prc,fuel,rt) = sum((dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint) $(not dhprd_ccs_prc(dhprd_prc))),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint)*aux_com(commodity,dhprd_prc,rt,region)/aux_all(dhprd_prc,rt,region));                                

out_dhprod_prc2(rpt_reg,dhprd_prc,fuel,rt) = sum((dhprd_dhind,commodity,region,v,ts,user_constraint)$(sameas(region,rpt_reg) $dhprd_prc_fuels(commodity,fuel) $aux_com(commodity,dhprd_prc,rt,region) $aux_all(dhprd_prc,rt,region) $veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint) $(not dhprd_ccs_prc(dhprd_prc))),
                             veda_vdd("var_fout",dhprd_dhind,dhprd_prc,rt,region,v,ts,user_constraint));                                

out_share_dh(region,rt)= share_dh(region,rt);

***********************************************
*** TABLE SYNTHETIC FUEL PRODUCTION  
***********************************************
sets
* synthetic fuels production processes (all)
    synprd_prc(Process) synthetic fuels production processes (all - with and without CCS)
    synprd_ccs_prc(Process) synthtetic fuel production processes with CCS
    c_liquids(Process) coal and gas to liquids processes
    c_gases(Process) coal to gas processes
    b_liquids(Process) biogenic liquids processes
    b_gases(Process) biogenic gases processes
    e_liquids(Process) e-liquids processes (PtL)
    ge_liquids(Process) green e-liquids processes (PtL-green)
    e_gases(Process) e-gases processes (PtG)
    ge_gases(Process) green e-gases processes (PtG-green)
   
* commodities for synthetic fuels and fuels used for synthetic fuel production 
    synprd_syn(Commodity) hydrogen production commodities /BIODME,BIODST,BIOEMHV,BIOETHA,BIOGAS,BIOHVO,BIOLIQ1,BIOMtaH,BIOPROP,GASNAT,GASP2G,OILDST,OILGSL,OILKER,OILNAP,SYNDME,SYNMtaH, SYNGDST,SYNGGSL,SYNGKER,SYNGLPG,SYNGNAP,SYNGOTH,GASP2G_G/
    gsynprd_syn(Commodity) green-efuels production commodities  /SYNGDST,SYNGGSL,SYNGKER,SYNGLPG,SYNGNAP,SYNGOTH,GASP2G_G/
   
* fuels used as input to synthetic fuels production
    synprd_coa(Commodity) coal to synthetic fuel production /COAHAR/
    synprd_gas(Commodity) natural gas to synthetic fuel production /GASNAT,SUPGAS/
    synprd_h2(Commodity) hydrogen to synthetic fuel production /SYNH2CT,SYNH2CU,SYNH2DT,BRFH2,SYNGH2CT,SYNGH2CU,SYNGH2DT/
    synprd_oil(Commodity) oil to synthetic fuel production /OILHFO/
    synprd_bio(Commodity) biofuels synthetic fuel production /BIOLGCFS,BIOOILFS,BIOSLU,BIOSTAFS,BIOSUGFS,BIOWOO,INDBLQ/
    synprd_elc(Commodity) electricity to synthetic fuel production  /ELCHIG,SUPELC/
    synprd_oth(Commodity) other fuels to synthetic fuel production /SUPHTH/

    synprd_all(Commodity) all commodites used to fuel synthetic fuels production processes
    /#synprd_coa, #synprd_gas, #synprd_h2, #synprd_oil, #synprd_bio, #synprd_elc, #synprd_oth/

* Create the rows of the table in the template file 
    synfuels_types /c_liquids, c_gases, b_liquids, b_gases, e_liquids, e_gases, ge_liquids, ge_gases/
    synfuels_prc_types(synfuels_types,Process)
    
    synprd_prc_fuels_in(Commodity,fuel) mapping of commodities to reporting fuels (used to generate the fuel consumption )
    /#synprd_coa.coal, #synprd_gas.gas, #synprd_h2.h2, #synprd_oil.oil, #synprd_bio.biomass, #synprd_elc.elec, #synprd_oth.other/ 

;

parameter
    out_synfuels(rpt_reg,synfuels_types,rt) synthetic fuel production by type of synthetic fuel (b-fuel or c-fuel or e-fuel)
    out_synfuels_prc(rpt_reg,process,synfuels_types,rt) synthetic fuel production by process and type of synthetic fuel (b-fuel or c-fuel or e-fuel) (internal parameter)
    in_synfuels(rpt_reg,fuel,rt) fuel consumption for producing synthetic fuels 
;

cf("BRF2_BTLFTDSL_CCS ")= 0.044;cf("BRF2_BTLFTDSL     ")= 0.044;cf("BRF2_ETHLGC       ")= 0.0268;cf("BRF1_PREETBE      ")= 0.0363;cf("BRF2_ETHLGC_CCS   ")= 0.0268;cf("BRF1_ETHAMIDO     ")= 0.0268;cf("BRF1_ETHSUCRI     ")= 0.0268;cf("BRF1_HVO          ")= 0.044;cf("BRF1_TRANSESTER   ")= 0.044;

* Select processes that produce synthetic liquids and consume at least one of the identified fuels for synthetic liquids production 
synprd_prc(synprd_prc_py) = sum((synprd_syn,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",synprd_syn,synprd_prc_py,rt,region,v,ts,user_constraint),1);
*sum((synprd_all,region,rt,v,ts,user_constraint)$veda_vdd("var_fin",synprd_all,synprd_prc_py,rt,region,v,ts,user_constraint), 1);
b_liquids(synprd_prc)=yes$synblq_prc_py(synprd_prc);
b_gases(synprd_prc)=yes$synbgs_prc_py(synprd_prc);
c_liquids(synprd_prc)=yes$synflq_prc_py(synprd_prc);
c_gases(synprd_prc)=yes$synfgs_prc_py(synprd_prc);
e_liquids(synprd_prc)=yes$(synelq_prc_py(synprd_prc) or synegrlq_prc_py(synprd_prc));
ge_liquids(synprd_prc)=yes$(synegrlq_prc_py(synprd_prc) or synegrgs_prc_py(synprd_prc));
e_gases(synprd_prc)=yes$(synegs_prc_py(synprd_prc) or synegrgs_prc_py(synprd_prc));
ge_gases(synprd_prc)=yes$synegrgs_prc_py(synprd_prc);
synprd_ccs_prc(synprd_prc) = sum((CO2_ccs,rt, region,v,ts,user_constraint)$veda_vdd("var_fout",CO2_ccs,synprd_prc,rt,region,v,ts,user_constraint),1);

synfuels_prc_types("c_liquids",c_liquids)=yes;synfuels_prc_types("c_gases",c_gases)=yes;
synfuels_prc_types("b_liquids",b_liquids)=yes;synfuels_prc_types("b_gases",b_gases)=yes;
synfuels_prc_types("e_liquids",e_liquids)=yes;synfuels_prc_types("e_gases",e_gases)=yes;
synfuels_prc_types("ge_liquids",ge_liquids)=yes;synfuels_prc_types("ge_gases",ge_gases)=yes;


* Calculate fuel consumption by synthetic fuel production process (total and by fuel)
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;
aux_all(synprd_prc,rt,region) = sum((synprd_all,v,ts,user_constraint)$veda_vdd("var_fin",synprd_all,synprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",synprd_all,synprd_prc,rt,region,v,ts,user_constraint));
aux_com(commodity,synprd_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",commodity,synprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",commodity,synprd_prc,rt,region,v,ts,user_constraint));

* Calculate production for synthetic fuels processes 
out_synfuels(rpt_reg,synfuels_types,rt)  = sum((synprd_prc,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$synfuels_prc_types(synfuels_types,synprd_prc)$veda_vdd("var_act","-",synprd_prc,rt,region,v,ts,user_constraint)),cf(synprd_prc)*veda_vdd("var_act","-",synprd_prc,rt,region,v,ts,user_constraint));
out_synfuels("EU-27",synfuels_types,rt) = sum(rpt_reg$eu27(rpt_reg),out_synfuels(rpt_reg,synfuels_types,rt)); 

out_synfuels_prc(rpt_reg,synprd_prc,synfuels_types,rt) =sum((region,v,ts,user_constraint)$(sameas(region, rpt_reg)$synfuels_prc_types(synfuels_types,synprd_prc)$veda_vdd("var_act","-",synprd_prc,rt,region,v,ts,user_constraint)),cf(synprd_prc)*veda_vdd("var_act","-",synprd_prc,rt,region,v,ts,user_constraint));

* Calculate fuel consumption for synthetic fuel processes with and without CCS
in_synfuels(rpt_reg,"elec",rt) = sum((region,synprd_elc,synprd_prc)$(sameas(region,rpt_reg) $synprd_prc_fuels_in(synprd_elc,"elec")), aux_com(synprd_elc,synprd_prc,rt,region));
*in_synfuels("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg), in_h2prod(rpt_reg,fuel,rt)); 
display in_synfuels;

***********************************************
*** TABLE FINAL ENERGY CONSUMPTION IN INDUSTRY
***********************************************

sets
* Industrial processes (all)
    nen_prc(Process) Non energy uses processes
    iis_prc(Process) Iron and Steel proceses
    inf_prc(Process) Non Ferrous metals proceses
    ich_prc(Process) Chemicals proceses
    ipp_prc(Process) Paper and Pulp proceses
    inm_prc(Process) Non Metallic Minerals proceses
    ioi_prc(Process) Other industry proceses
    chp_ind_prc(Process) On site CHP processes: fuel input to CHP in industry is excluded from final consumption
    boi_ind_prc(Process) on-site processes that deliver on-site heat: heat output from these boilers should be excluded from final consumption of heat in industry
    blf_prc(Process) On site Blast furnance processes: fuel input to blust furnance processes is excluded from final consumption
    ih2_prc(Process) On-site hydrogen production processes: fuel consumption from on-site produced hydrogen is excluded from final consumption
    ibio_prc(Process) On-site biofuels production processes: fuel consumption from on-site produced biofuels is excluded from final consumption 
    idm_prc(Process) Demand processes (should be excluded from the industrial consumption)/ICHDEMAND00,INFDEMAND00,INMDEMAND00,IOIDEMAND00/
    ind_subsec Industrial Subsectors /IIS, INM, INF, ICH, IPP, IOI/
    ind_prc_subsec(Process, ind_subsec) industrial processes to subsectors
    ind_liqftech(Process) Industry fuel tech processes to distribute liquids /INDHFO00,INDLFO00,INDLPG00,INDNAP00,INDRFG00/

* fuels used as input to industrial proceseses
    enc_nen(Commodity) fuels used in Non-Energy Uses /GASNAT,OILDST,OILGSL,OILHFO,OILKER,OILLPG,OILNAP,OILNEU,OILOTH,OILRFG/
    coa_ind(Commodity) coal /INDCOL,INDCOA,INDCOB,INDCOK/
    oil_ind(Commodity) oil products /INDHFO,INDNAP,INDLFO,INDLPG,INDRFG/
    gas_ind(Commodity) natural gas and derived gases /INDBFT,INDBFG,INDCOG,INDCOP,INDGAS/
    bgs_ind(Commodity) biogas /INDBGS/
    h2_ind(Commodity)  hydrogen /INDHH2,INDGHH2/
    h2_indprc(Process) fuel tech processes delivering hydrogen to industrial sectors /INDGH2C01,INDGGH2C01/
    bio_ind(Commodity) biomass wastes and bioliquids /INDBIO,INDMUN,INDSLU/
    hth_ind(Commodity) heat (marketed and non-marketed /ICHHTH,ICLHTH,ICUHTH,IISHTH,INDHTH,INFHTH,INMHTH,IOIHTH,IPPHTH,REFHTH/
    elc_ind(Commodity) electricity /INDELC/
    oth_ind(Commodity) other fuels in industry /INDSOL,INDGEO/
    env_ind(Commodity) environmental heat in industry /INDAHT/
    ind_all(Commodity) all commodites used to fuel industrial processes /#coa_ind, #oil_ind, #gas_ind, #bgs_ind, #h2_ind, #bio_ind, #hth_ind, #elc_ind, #oth_ind, #env_ind/
    ind_abio(Commodity) all biogenic commodities used to fuel industrial processes /#bgs_ind, #bio_ind/
    blf_ind(Commodity) Output from Blast Furnances /GASBFG,MISBFS,MISRIR,GASBFT,GASIIS,MISCST/
    ingas_ind(Commodity) Input gases to industry that are treated as "natural gas" /GASNAT, GASP2G, GASP2G_G/

* Treatment of bioliquids and e-liquids in industry
    blq_ind_com(Commodity) bioliquids and e-liquids in industry /BIOLIQ/ 
* Create the table rows     
    ind_com_fuel(Commodity,fuel) mapping of commodities to fuels for industry /#coa_ind.coal, #oil_ind.oil, #gas_ind.gas, #bgs_ind.biogas, #elc_ind.elec, #bio_ind.biomass, #hth_ind.heat, #oth_ind.other,#h2_ind.h2, #env_ind.env_heat/
    ind_com_subsec(Commodity, ind_subsec)/(ICHHTH,ICLHTH).ICH, IISHTH.IIS, (ICUHTH,INFHTH).INF, INMHTH.INM, IOIHTH.IOI,IPPHTH.IPP/
;
alias (ind_subsec2, ind_subsec);

parameters
    out_nen(rpt_reg,rt) total energy consumption for non-energy uses
    out_ind(rpt_reg,ind_subsec,fuel,rt) final energy consumption in industrial subsectors
    out_ind_h2(rpt_reg,fuel,rt) final hydrogen consumption of total industry sector 
    aux_h2(commodity,process,rt,region)
;

* Non-energy uses process selection 
nen_prc(nen_py) = sum((enc_nen,rt,region,v,ts,user_constraint)$veda_vdd("var_fin",enc_nen,nen_py,rt,region,v,ts,user_constraint),1);
* Non-energy uses consumption
out_nen(rpt_reg,rt)  = sum((nen_prc,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_act","-",nen_prc,rt,region,v,ts,user_constraint)),veda_vdd("var_act","-",nen_prc,rt,region,v,ts,user_constraint));
out_nen("EU-27",rt) = sum(rpt_reg$eu27(rpt_reg), out_nen(rpt_reg,rt));

* On-Site CHPs, blast furnances, hydrogen and biofuels production and other fuel-tech processes
chp_ind_prc(dhprd_aut_prc) = sum((hth_ind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hth_ind,dhprd_aut_prc,rt,region,v,ts,user_constraint),1);
blf_prc(process) = sum((rt,region,v,ts,user_constraint)$veda_vdd("var_fout","GASBFG",process,rt,region,v,ts,user_constraint),1);
ih2_prc(process) = sum((h2_ind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",h2_ind,process,rt,region,v,ts,user_constraint),1)*sum((ind_all,rt,region,v,ts,user_constraint)$veda_vdd("var_fin",ind_all,Process,rt,region,v,ts,user_constraint),1);    
ibio_prc(process) = sum((ind_abio,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",ind_abio,process,rt,region,v,ts,user_constraint),1)*sum((ind_all,rt,region,v,ts,user_constraint)$veda_vdd("var_fin",ind_all,Process,rt,region,v,ts,user_constraint),1);    

* Industrial processes in sucbsectors 
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;aux_com2(commodity,process,rt,region)=0;aux_h2(commodity,process,rt,region)=0;

aux_com2(hth_ind,"INDIHTH00",rt,region)=sum((v,ts,user_constraint)$veda_vdd("var_fout",hth_ind,"INDIHTH00",rt,region,v,ts,user_constraint), veda_vdd("var_fout",hth_ind,"INDIHTH00",rt,region,v,ts,user_constraint));

* Bioliquids in total bio for industry 
aux_all("INDBIO00",rt,region) = sum((blq_ind_com,v,ts,user_constraint)$veda_vdd("var_fin",blq_ind_com,"INDBIO00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",blq_ind_com,"INDBIO00",rt,region,v,ts,user_constraint));

aux_com(ind_all,process,rt,region)$((not chp_ind_prc(process)) $(not idm_prc(process)) $(not blf_prc(process)) $(iis_ind_py(process) or inf_ind_py(process) or ich_ind_py(process) or ipp_ind_py(process) or inm_ind_py(process) or ioi_ind_py(process))) =
    sum((v,ts,user_constraint)$veda_vdd("var_fin",ind_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",ind_all,process,rt,region,v,ts,user_constraint));

iis_prc(iis_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,iis_ind_py,rt,region),1);inf_prc(inf_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,inf_ind_py,rt,region),1);
ich_prc(ich_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,ich_ind_py,rt,region),1);ipp_prc(ipp_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,ipp_ind_py,rt,region),1);
inm_prc(inm_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,inm_ind_py,rt,region),1);ioi_prc(ioi_ind_py)=yes$sum((ind_all,rt,region)$aux_com(ind_all,ioi_ind_py,rt,region),1);

ind_prc_subsec(iis_prc,"iis")=yes;ind_prc_subsec(inf_prc,"inf")=yes;ind_prc_subsec(ich_prc,"ich")=yes;
ind_prc_subsec(ipp_prc,"ipp")=yes;ind_prc_subsec(inm_prc,"inm")=yes;ind_prc_subsec(ioi_prc,"ioi")=yes;

* Generic boilers producing on-site heat: their heat production should be excluded from total heat consumption in industry
boi_ind_prc(process)$(iis_prc(process) or inf_prc(process) or ich_prc(process) or ipp_prc(process) or inm_prc(process) or ioi_prc(process) and (not blf_prc(process))) = yes$sum((hth_ind,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hth_ind,process,rt,region,v,ts,user_constraint),1);    

out_ind(rpt_reg,ind_subsec,"elec",rt)  = (sum((ind_all,process,region)$(sameas(region,rpt_reg)$ind_com_fuel(ind_all,"elec")$ind_prc_subsec(process, ind_subsec)$aux_com(ind_all,process,rt,region)),aux_com(ind_all,process,rt,region)))$(not sameas("elec","heat"))
 + (sum((ind_all,process,region)$(sameas(region,rpt_reg)$ind_com_fuel(ind_all,"elec")$ind_com_subsec(ind_all, ind_subsec)$aux_com2(ind_all,process,rt,region)),aux_com2(ind_all,process,rt,region)))$(sameas("elec","heat"));

* do not include on-site hydrogen production (if the produced hydrogen is consumed in at least one industrial process)

aux_com(commodity,process,rt,region)=0;
aux_com(h2_ind,chp_ind_prc,rt,region)=sum((v,ts,user_constraint)$veda_vdd("var_fin",h2_ind,chp_ind_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",h2_ind,chp_ind_prc,rt,region,v,ts,user_constraint));
aux_com(h2_ind,process,rt,region)$( (not idm_prc(process)) $(not blf_prc(process)) $(chp_ind_prc(process) or iis_ind_py(process) or inf_ind_py(process) or ich_ind_py(process) or ipp_ind_py(process) or inm_ind_py(process) or ioi_ind_py(process))) =
   sum((v,ts,user_constraint)$veda_vdd("var_fin",h2_ind,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",h2_ind,process,rt,region,v,ts,user_constraint));


* do not include on-site hydrogen production in the final energy consumption of hydrogen - scale final energy consumptption with the pipeline hydrognen output 
*out_ind(rpt_reg,"h2",rt)$(sameas(region,rpt_reg) $veda_vdd("var_fout",h2_ind,process,rt,region,v,ts,user_constraint)),1) = out_ind(rpt_reg,ind_subsec,"h2",rt)* sum((region,h2_ind,h2_indprc,v,ts,user_constraint)$(sameas(region,rpt_reg) $veda_vdd("var_fout",h2_ind,h2_indprc,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",h2_ind,h2_indprc,rt,region,v,ts,user_constraint))/sum((region,h2_ind,process,v,ts,user_constraint)$(sameas(region,rpt_reg) $veda_vdd("var_fout",h2_ind,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",h2_ind,process,rt,region,v,ts,user_constraint));

out_ind_h2(rpt_reg,"h2",rt)  = sum((ind_all,process,region)$(sameas(region,rpt_reg)$ind_com_fuel(ind_all,"h2")$aux_com(ind_all,process,rt,region)),aux_com(ind_all,process,rt,region));

display out_ind_h2;

* do not include on-site biofuels production (if the produced biofuels is consumed in at least one industrial process)
out_ind(rpt_reg,ind_subsec,fuel,rt)$(sameas("biomass",fuel) $(out_ind(rpt_reg,ind_subsec,fuel,rt) ge sum((bio_ind,ibio_prc,region,v,ts,user_constraint)$(sameas(region,rpt_reg)$ind_com_fuel(bio_ind,fuel)$(ind_prc_subsec(ibio_prc,ind_subsec))$veda_vdd("var_fout",bio_ind,ibio_prc,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",bio_ind,ibio_prc,rt,region,v,ts,user_constraint))))  =out_ind(rpt_reg,ind_subsec,fuel,rt) - sum((bio_ind,ibio_prc,region,v,ts,user_constraint)$(sameas(region,rpt_reg)$ind_com_fuel(bio_ind,fuel)$(ind_prc_subsec(ibio_prc,ind_subsec))$veda_vdd("var_fout",bio_ind,ibio_prc,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",bio_ind,ibio_prc,rt,region,v,ts,user_constraint)); 

* Correction of biomass consumption to remove bioliquids and e-liquids from it
out_ind(rpt_reg,ind_subsec,"bioliquids",rt)$sum(ind_subsec2,out_ind(rpt_reg,ind_subsec2,"biomass",rt)) = sum(region$sameas(region,rpt_reg),aux_all("INDBIO00",rt,region))*out_ind(rpt_reg,ind_subsec,"biomass",rt)/sum(ind_subsec2,out_ind(rpt_reg,ind_subsec2,"biomass",rt));
out_ind(rpt_reg,ind_subsec,"biomass",rt) = out_ind(rpt_reg,ind_subsec,"biomass",rt)-out_ind(rpt_reg,ind_subsec,"bioliquids",rt);



$ontext
* correct gas consumption by subtracting e-gases entered into the INDGAS00 process and add these to the biogases/e-gases category
aux_com(commodity,process,rt,region)=0;
aux_com(ge_gases_com,"INDGAS00",rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",ge_gases_com,"INDGAS00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_gases_com,"INDGAS00",rt,region,v,ts,user_constraint));
aux_com(ingas_ind,"INDGAS00",rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",ingas_ind,"INDGAS00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ingas_ind,"INDGAS00",rt,region,v,ts,user_constraint));
out_ind(rpt_reg,ind_subsec,"biogas",rt)$sum((ingas_ind,region)$sameas(region,rpt_reg), aux_com(ingas_ind,"INDGAS00",rt,region)) = out_ind(rpt_reg,ind_subsec,"biogas",rt)+out_ind(rpt_reg,ind_subsec,"gas",rt)*sum(region$sameas(region,rpt_reg), sum(ge_gases_com, aux_com(ge_gases_com,"INDGAS00",rt,region))/sum(ingas_ind, aux_com(ingas_ind,"INDGAS00",rt,region)));
out_ind(rpt_reg,ind_subsec,"gas",rt) = out_ind(rpt_reg,ind_subsec,"gas",rt)*sum(region$sameas(region,rpt_reg),(1- (sum(ge_gases_com,aux_com(ge_gases_com,"INDGAS00",rt,region))/sum(ingas_ind,aux_com(ingas_ind,"INDGAS00",rt,region)))$sum(ingas_ind,aux_com(ingas_ind,"INDGAS00",rt,region)) ) );

* correct liquids consumption by subtracting e-liquids entered into the INDOIL00 processes and add these to the bioliquids/e-liquids category
aux_com(commodity,process,rt,region)=0;
aux_com(ge_liquids_com,ind_liqftech,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",ge_liquids_com,ind_liqftech,rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_liquids_com,ind_liqftech,rt,region,v,ts,user_constraint));
aux_com(oil_ind,ind_liqftech,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fout",oil_ind,ind_liqftech,rt,region,v,ts,user_constraint), veda_vdd("var_fout",oil_ind,ind_liqftech,rt,region,v,ts,user_constraint));

out_ind(rpt_reg,ind_subsec,"bioliquids",rt) = out_ind(rpt_reg,ind_subsec,"bioliquids",rt)+(out_ind(rpt_reg,ind_subsec,"oil",rt)*sum(region$sameas(region,rpt_reg), sum((ge_liquids_com,ind_liqftech), aux_com(ge_liquids_com,ind_liqftech,rt,region))/sum((oil_ind,ind_liqftech), aux_com(oil_ind,ind_liqftech,rt,region))))$sum((oil_ind,ind_liqftech,region)$sameas(region,rpt_reg), aux_com(oil_ind,ind_liqftech,rt,region));
out_ind(rpt_reg,ind_subsec,"oil",rt) = out_ind(rpt_reg,ind_subsec,"oil",rt)*(1-sum(region$sameas(region,rpt_reg), sum((ge_liquids_com,ind_liqftech), aux_com(ge_liquids_com,ind_liqftech,rt,region))/sum((oil_ind,ind_liqftech), aux_com(oil_ind,ind_liqftech,rt,region)))$sum((oil_ind,ind_liqftech,region)$sameas(region,rpt_reg), aux_com(oil_ind,ind_liqftech,rt,region)));
$offtext
* correct liquids consumption by subtracting e-liquids entered into the INDOIL00 processes and add these to the bioliquids/e-liquids category
aux_com(commodity,process,rt,region)=0;
aux_com(ge_liquids_com,ind_liqftech,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",ge_liquids_com,ind_liqftech,rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_liquids_com,ind_liqftech,rt,region,v,ts,user_constraint));
aux_com(oil_ind,ind_liqftech,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fout",oil_ind,ind_liqftech,rt,region,v,ts,user_constraint), veda_vdd("var_fout",oil_ind,ind_liqftech,rt,region,v,ts,user_constraint));

out_ind("EU-27",ind_subsec,"elec",rt) = sum(rpt_reg$eu27(rpt_reg), out_ind(rpt_reg,ind_subsec,"elec",rt));

***************************************************************
*** TABLE FINAL ENERGY CONSUMPTION IN SERVICES AND AGRICULTURE
***************************************************************

sets
* fuels consumed in agriculture 
    coa_agr(Commodity) coal in agriculture /AGRCOA/
    oil_agr(Commodity) oil in agriculture /AGRLPG,AGRDST,AGROIL/
    bdl_agr(Commodity) biodiesel in agriculture /AGRBDL/
    gas_agr(Commodity) gas in agriculture /AGRGAS/
    bgs_agr(Commodity) biogas in agriculture /AGRBGS/
    elc_agr(Commodity) electricity in agriculture /AGRELC/
    bio_agr(Commodity) biomass in agriculture /AGRBIO/
    hth_agr(Commodity) heat in agriculture /AGRHET/
    h2_agr(Commodity) hydrogen in agriculture sectors/AGRHH2,AGRGHH2/
    env_agr(Commodity) environmental heat in agriculture /AGRAHT,AGRGHT/
    oth_agr(Commodity) other fuels in agriculture /AGRGEO,AGRSOL/
    hta_agr(Commodity) on-site heat in agriculture sectors /AGR_Low_Ent_Het,AGR_Spe_Het_Use/
    agr_all(Commodity) all fuels in agriculture /#coa_agr, #oil_agr, #bdl_agr, #gas_agr, #bgs_agr, #elc_agr, #bio_agr, #h2_agr, #hth_agr, #env_agr, #oth_agr/

* fuels consumed in commercial sectors 
    coa_com(Commodity) coal in commercial sectors /COMCOA/
    oil_com(Commodity) oil products in commercial sectors /COMLPG,COMOIL/
    bdl_com(Commodity) bioliquids in commercial sectors /COMBDL/
    gas_com(Commodity) natural gas in commercial sectors /COMGAS/
    bgs_com(Commodity) biogas in commercial sectors /COMBGS/
    elc_com(Commodity) electricity in commercial sectors /COMELC/
    bio_com(Commodity) biomass and wastes in commercial sectors /COMBIO/
    hth_com(Commodity) district heat in commercial sectors /COMHET/
    hta_com(Commodity) on-site heat in commercial sectors /#hth_com, NR_ES-HO-SpHeat,NR_ES-HO-WatHeat,NR_ES-HR-SpHeat,NR_ES-HR-WatHeat,NR_ES-OF-SpHeat,NR_ES-OF-WatHeat,NR_ES-SL-SpHeat,NR_ES-SL-WatHeat,NR_ES-SR-SpHeat,NR_ES-SR-WatHeat,NR_ES-SS-SpHeat,NR_ES-SS-WatHeat/
    sh_com(Commodity) /NR_ES-HO-SpHeat,NR_ES-HR-SpHeat,NR_ES-OF-SpHeat,NR_ES-SL-SpHeat,NR_ES-SR-SpHeat,NR_ES-SS-SpHeat/
    wh_com(Commodity) /NR_ES-HO-WatHeat,NR_ES-HR-WatHeat,NR_ES-OF-WatHeat,NR_ES-SL-WatHeat,NR_ES-SR-WatHeat,NR_ES-SS-WatHeat/
    sc_com(Commodity) /NR_ES-HO-SpCool,NR_ES-HR-SpCool,NR_ES-OF-SpCool,NR_ES-SL-SpCool,NR_ES-SR-SpCool,NR_ES-SS-SpCool/
    h2_com(Commodity)  hydrogen in commercial sectors /COMHH2,COMGHH2/
    env_com(Commodity) environmental heating and cooling in commercial sectors /COMAHT,COMGHT/
    oth_com(Commodity) other energy carriers in commmercial sectors /COMGEO,COMSOL/
    com_all(Commodity) all fuels in commercial sectors /  #coa_com,#oil_com,#bdl_com,#gas_com,#bgs_com,#elc_com,#bio_com,#hth_com,#h2_com,#env_com,#oth_com /
    blq_com_com(Commodity) bioliquids and e-liquids in commercial sectors (blending) /BIOLIQ/
    bgs_com_com(Commodity) biogases and e-gases in commercial sectors (blending) /BIOGAS/

* Commercial energy services
    com_dem_com(Commodity) /NR_ES-HO-SpHeat,NR_ES-HO-WatHeat,NR_ES-HO-SpCool,NR_ES-HO-Cook,NR_ES-HR-SpHeat,NR_ES-HR-WatHeat,NR_ES-HR-SpCool,NR_ES-HR-Cook,NR_ES-OF-SpHeat,NR_ES-OF-WatHeat,NR_ES-OF-SpCool,NR_ES-OF-Cook,NR_ES-SL-SpHeat,NR_ES-SL-WatHeat,NR_ES-SL-SpCool,NR_ES-SL-Cook,NR_ES-SR-SpHeat,NR_ES-SR-WatHeat,NR_ES-SR-SpCool,NR_ES-SR-Cook,NR_ES-SS-SpHeat,NR_ES-SS-WatHeat,NR_ES-SS-SpCool,NR_ES-SS-Cook,NRbldg_BuildLight,NRbldg_N-BuildLight1,NRbldg_N-BuildLight2,NRbldg_N-BuildLight3,NRbldg_N-BuildLight4,NRbldg_N-BuildLight5,
    NRbldg_Refrig,NRbldg_N-Refrig1,NRbldg_N-Refrig2,NRbldg_N-Refrig3,NRbldg_N-Refrig4,
    NRbldg_StLight,NRbldg_N-StLight,NRbldg_N-StLight2,
    NRbldg_ICTM,NRbldg_N-ICTM1,
    NRbldg_Vent,NRbldg_BuildTech/
    com_esd /COM_HO_SpHeat,COM_HR_SpHeat,COM_OF_SpHeat,COM_SL_SpHeat,COM_SS_SpHeat,COM_SR_SpHeat,
    COM_HO_WatHeat,COM_HR_WatHeat,COM_OF_WatHeat,COM_SL_WatHeat,COM_SS_WatHeat,COM_SR_WatHeat,
    COM_HO_SpCool,COM_HR_SpCool,COM_OF_SpCool,COM_SL_SpCool,COM_SS_SpCool,COM_SR_SpCool,
    COM_HO_Cook,COM_HR_Cook,COM_OF_Cook,COM_SL_Cook,COM_SS_Cook,COM_SR_Cook,
    COM_Ref,COM_StLight,COM_Vent,COM_ICT,COM_BuildTech/
    com_esd_com(com_esd,commodity) /COM_HO_SpHeat.NR_ES-HO-SpHeat,COM_HR_SpHeat.NR_ES-HR-SpHeat,COM_OF_SpHeat.NR_ES-OF-SpHeat,COM_SL_SpHeat.NR_ES-SL-SpHeat,COM_SR_SpHeat.NR_ES-SR-SpHeat,COM_SS_SpHeat.NR_ES-SS-SpHeat,
    COM_HO_SpCool.NR_ES-HO-SpCool,COM_HR_SpCool.NR_ES-HR-SpCool,COM_OF_SpCool.NR_ES-OF-SpCool,COM_SL_SpCool.NR_ES-SL-SpCool,COM_SR_SpCool.NR_ES-SR-SpCool,COM_SS_SpCool.NR_ES-SS-SpCool,
    COM_HO_WatHeat.NR_ES-HO-WatHeat,COM_HR_WatHeat.NR_ES-HR-WatHeat,COM_OF_WatHeat.NR_ES-OF-WatHeat,COM_SL_WatHeat.NR_ES-SL-WatHeat,COM_SR_WatHeat.NR_ES-SR-WatHeat,COM_SS_WatHeat.NR_ES-SS-WatHeat,
    COM_HO_Cook.NR_ES-HO-Cook,COM_HR_Cook.NR_ES-HR-Cook,COM_OF_Cook.NR_ES-OF-Cook,COM_SL_Cook.NR_ES-SL-Cook,COM_SR_Cook.NR_ES-SR-Cook,COM_SS_Cook.NR_ES-SS-Cook,
    COM_Ref.(NRbldg_Refrig,NRbldg_N-Refrig1,NRbldg_N-Refrig2,NRbldg_N-Refrig3,NRbldg_N-Refrig4),
    COM_StLight.(NRbldg_StLight,NRbldg_N-StLight,NRbldg_N-StLight2),
    COM_Vent.NRbldg_Vent,
    COM_ICT.(NRbldg_ICTM,NRbldg_N-ICTM1),
    COM_BuildTech.NRbldg_BuildTech/

*   processes in commercial and agriculture sectors 
    chp_com_prc(Process) On site CHP processes: fuel input to CHP in commercial sectors is excluded from final consumption
    com_prc(Process) Commercial processes excluding on site CHP plants 
    agr_prc(Process) Agriculture processes excluding on site CHP plants
    

* Create row tables 
    agrcom_all(Commodity) all fuels in agriculture and commerical sectors /#agr_all, #com_all/
*com_all(Commodity)/ #coa_com,#oil_com,#bdl_com,#gas_com,#bgs_com,#elc_com,#bio_com,#hth_com,#h2_com,#env_com,#oth_com/
    agrcom_com_fuel(commodity,fuel) /(#coa_agr,#coa_com).coal, (#oil_agr,#oil_com).oil, (#bdl_agr,#bdl_com).bioliquids, (#gas_agr,#gas_com).gas, (#bgs_com,#bgs_agr).biogas,(#elc_agr,#elc_com).elec, (#bio_agr,#bio_com).biomass, (#hth_agr,#hth_com).heat, (#oth_agr,#oth_com).other,(#h2_com,#h2_agr).h2, (#env_com,#env_agr).env_heat/
    agr_com_fuel(commodity, fuel) fuels for agriculture sector only /#coa_agr.coal, #oil_agr.oil, #bdl_agr.bioliquids, #gas_agr.gas, #bgs_agr.biogas,#elc_agr.elec, #bio_agr.biomass, #hth_agr.heat, #oth_agr.other,#h2_agr.h2, #env_agr.env_heat/
* Create the table rows 
    com_com_fuel(commodity,fuel) /#coa_com.coal, #oil_com.oil, #bdl_com.bioliquids, #gas_com.gas, #bgs_com.biogas, #elc_com.elec, #bio_com.biomass, #hth_com.heat, #oth_com.other,#h2_com.h2, #env_com.env_heat/
*
;



parameter
    out_com(rpt_reg,fuel,rt) final energy consumption in commercial and agriculture sectors
    out_com_esd(rpt_reg,com_esd,fuel,rt) final energy consumption in commercial by end use
    out_com_h2(rpt_reg,fuel,rt) final hydrogen consumption of hydrogen in commerical sector
    out_agr(rpt_reg,fuel,rt) final energy consumption in agriculture sector only
    out_agr_h2(rpt_reg,fuel,rt)
    out_com_esd_prc(rpt_reg,com_esd,process,fuel,rt) final energy consumption in residential by end use
    out_prc_com(rpt_reg,process,fuel,rt) final energy consumption in commercial and agriculture sectors by process
    test_com, test2_com;
;

    
    

* On-site CHPs to be excluded from final energy consumption 
chp_com_prc(dhprd_prc_py) = sum((hta_com,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_com,dhprd_prc_py,rt,region,v,ts,user_constraint),1)+
                             sum((hta_agr,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_agr,dhprd_prc_py,rt,region,v,ts,user_constraint),1);

* Calculate fuel consumption in commercial and agriculture sectors 
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;

out_agr(rpt_reg,fuel,rt)  = sum((agrcom_all,process,region)$(sameas(region,rpt_reg)$agr_com_fuel(agrcom_all,fuel)$aux_com(agrcom_all,process,rt,region)),aux_com(agrcom_all,process,rt,region));

com_prc(process)$(not chp_com_prc(process)) = yes$sum((region,rt,v,com_all,ts,user_constraint)$veda_vdd("var_fin",com_all,process,rt,region,v,ts,user_constraint), 1); 
agr_prc(process)$(not chp_com_prc(process)) = yes$sum((region,rt,v,agr_all,ts,user_constraint)$veda_vdd("var_fin",agr_all,process,rt,region,v,ts,user_constraint), 1); 



*aux_com(com_all,process,rt,region)$(not chp_com_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fin",com_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",com_all,process,rt,region,v,ts,user_constraint));

aux_com(com_all,process,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",com_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",com_all,process,rt,region,v,ts,user_constraint));

out_com(rpt_reg,"elec",rt)  = sum((agrcom_all,process,region)$(sameas(region,rpt_reg)$com_com_fuel(agrcom_all,"elec")$aux_com(agrcom_all,process,rt,region)),aux_com(agrcom_all,process,rt,region));
out_com_h2(rpt_reg,"h2",rt)  = sum((com_all,process,region)$(sameas(region,rpt_reg)$com_com_fuel(com_all,"h2")$aux_com(com_all,process,rt,region)),aux_com(com_all,process,rt,region));

aux_com(agr_all,process,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",agr_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",agr_all,process,rt,region,v,ts,user_constraint));
out_agr_h2(rpt_reg,"h2",rt)  = sum((agr_all,process,region)$(sameas(region,rpt_reg)$agr_com_fuel(agr_all,"h2")$aux_com(agr_all,process,rt,region)),aux_com(agr_all,process,rt,region));



test_com(rpt_reg,process,rt)= sum((region,v,ts,user_constraint,com_dem_com)$(sameas(region,rpt_reg)$veda_vdd("var_fout",com_dem_com,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",com_dem_com,process,rt,region,v,ts,user_constraint));

*display test_com;

out_com_esd_prc(rpt_reg,com_esd,process,"elec",rt)$test_com(rpt_reg,process,rt)  = sum((com_all,region)$(sameas(region,rpt_reg)$com_com_fuel(com_all,"elec")$aux_com(com_all,process,rt,region)$sum((com_dem_com,v,ts,user_constraint)$(com_esd_com(com_esd,com_dem_com)$veda_vdd("var_fout",com_dem_com,process,rt,region,v,ts,user_constraint)), 1)),aux_com(com_all,process,rt,region))*sum((region,v,ts,user_constraint,com_dem_com)$(sameas(region,rpt_reg)$com_esd_com(com_esd,com_dem_com)$veda_vdd("var_fout",com_dem_com,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",com_dem_com,process,rt,region,v,ts,user_constraint))/test_com(rpt_reg,process,rt);
out_com_esd(rpt_reg,com_esd,"elec",rt)  = sum(process$out_com_esd_prc(rpt_reg,com_esd,process,"elec",rt),out_com_esd_prc(rpt_reg,com_esd,process,"elec",rt) );




* correct consumption for bioliquids in case these are consumed in COMBIO00
aux_all("COMBIO00",rt,region) = sum((blq_com_com,v,ts,user_constraint)$veda_vdd("var_fin",blq_com_com,"COMBIO00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",blq_com_com,"COMBIO00",rt,region,v,ts,user_constraint));
*out_com(rpt_reg,"bioliquids",rt)  = sum(region$sameas(region,rpt_reg), aux_all("COMBIO00",rt,region)); 
out_agr(rpt_reg,"bioliquids",rt)  = sum(region$sameas(region,rpt_reg), aux_all("AGRBIO00",rt,region)); 
*out_com(rpt_reg,"biomass",rt)  = out_com(rpt_reg,"biomass",rt)-out_com(rpt_reg,"bioliquids",rt); 
out_agr(rpt_reg,"biomass",rt)  = out_agr(rpt_reg,"biomass",rt)-out_agr(rpt_reg,"bioliquids",rt); 
$ontext
* correct consumption for biogases in case these are consumed in COMBIO00 - they should allocated as biogases and not as solid biomass 
aux_all(process,rt,region)=0;
aux_all("COMBIO00",rt,region) = sum((bgs_com_com,v,ts,user_constraint)$veda_vdd("var_fin",bgs_com_com,"COMBIO00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",bgs_com_com,"COMBIO00",rt,region,v,ts,user_constraint));
out_com(rpt_reg,"biogas",rt)  = out_com(rpt_reg,"biogas",rt) + sum(region$sameas(region,rpt_reg), aux_all("COMBIO00",rt,region)); 
out_agr(rpt_reg,"biogas",rt)  = out_agr(rpt_reg,"biogas",rt) + sum(region$sameas(region,rpt_reg), aux_all("AGRBIO00",rt,region)); 
out_com(rpt_reg,"biomass",rt)  = out_com(rpt_reg,"biomass",rt)-sum(region$sameas(region,rpt_reg), aux_all("COMBIO00",rt,region));
out_agr(rpt_reg,"biomass",rt)  = out_agr(rpt_reg,"biomass",rt)-sum(region$sameas(region,rpt_reg), aux_all("AGRBIO00",rt,region));

* correct gas consumption by subtracting e-gases entered into the COMGAS00 process and add these to the biogases/e-gases category
aux_all(process,rt,region)=0;
aux_all("COMGAS00",rt,region) = sum((ge_gases_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_gases_com,"COMGAS00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_gases_com,"COMGAS00",rt,region,v,ts,user_constraint));
aux_all("AGRGAS00",rt,region) = sum((ge_gases_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_gases_com,"AGRGAS00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_gases_com,"AGRGAS00",rt,region,v,ts,user_constraint));
out_com(rpt_reg,"gas",rt) = out_com(rpt_reg,"gas",rt) - sum(region$sameas(region,rpt_reg), aux_all("COMGAS00",rt,region)+aux_all("AGRGAS00",rt,region));
out_agr(rpt_reg,"gas",rt) = out_agr(rpt_reg,"gas",rt) - sum(region$sameas(region,rpt_reg), aux_all("AGRGAS00",rt,region));
out_com(rpt_reg,"biogas",rt) = out_com(rpt_reg,"biogas",rt) + sum(region$sameas(region,rpt_reg), aux_all("COMGAS00",rt,region)+aux_all("AGRGAS00",rt,region));
out_agr(rpt_reg,"biogas",rt) = out_agr(rpt_reg,"biogas",rt) + sum(region$sameas(region,rpt_reg), aux_all("AGRGAS00",rt,region));

test2_com(rpt_reg,rt)=1;
test2_com(rpt_reg,rt)$out_com(rpt_reg,"gas",rt) = sum(com_esd, out_com_esd(rpt_reg,com_esd,"gas",rt))/out_com(rpt_reg,"gas",rt);
out_com_esd(rpt_reg,com_esd,"gas",rt) = out_com_esd(rpt_reg,com_esd,"gas",rt) *test2_com(rpt_reg,rt);
test2_com(rpt_reg,rt)=1;
test2_com(rpt_reg,rt)$out_com(rpt_reg,"biogas",rt) = sum(com_esd, out_com_esd(rpt_reg,com_esd,"biogas",rt))/out_com(rpt_reg,"biogas",rt);
out_com_esd(rpt_reg,com_esd,"biogas",rt) = out_com_esd(rpt_reg,com_esd,"biogas",rt) *test2_com(rpt_reg,rt);


* correct liquids consumption by subtracting e-liquids entered into the COMOIL00 prcess and add them to the bioliquids/e-liquids category
aux_all(process,rt,region)=0;
aux_all("COMOIL00",rt,region) = sum((ge_liquids_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_liquids_com,"COMOIL00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_liquids_com,"COMOIL00",rt,region,v,ts,user_constraint));
aux_all("AGROIL00",rt,region) = sum((ge_liquids_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_liquids_com,"AGROIL00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_liquids_com,"AGROIL00",rt,region,v,ts,user_constraint));
out_com(rpt_reg,"oil",rt) = out_com(rpt_reg,"oil",rt) - sum(region$sameas(region,rpt_reg), aux_all("COMOIL00",rt,region)+aux_all("AGROIL00",rt,region));
out_com(rpt_reg,"bioliquids",rt) = out_com(rpt_reg,"bioliquids",rt) + sum(region$sameas(region,rpt_reg), aux_all("COMOIL00",rt,region)+aux_all("AGROIL00",rt,region));
out_com_esd(rpt_reg,com_esd,"oil",rt)$(out_com(rpt_reg,"oil",rt)+out_com(rpt_reg,"bioliquids",rt)) = out_com_esd(rpt_reg,com_esd,"oil",rt)*out_com(rpt_reg,"oil",rt)/(out_com(rpt_reg,"oil",rt)+out_com(rpt_reg,"bioliquids",rt));
out_com_esd(rpt_reg,com_esd,"bioliquids",rt)$(out_com(rpt_reg,"oil",rt)+out_com(rpt_reg,"bioliquids",rt)) = out_com_esd(rpt_reg,com_esd,"oil",rt)*out_com(rpt_reg,"bioliquids",rt)/(out_com(rpt_reg,"oil",rt)+out_com(rpt_reg,"bioliquids",rt));

$offtext 
out_agr(rpt_reg,"oil",rt) = out_agr(rpt_reg,"oil",rt) - sum(region$sameas(region,rpt_reg), aux_all("AGROIL00",rt,region));
out_agr(rpt_reg,"bioliquids",rt) = out_agr(rpt_reg,"bioliquids",rt) + sum(region$sameas(region,rpt_reg), aux_all("AGROIL00",rt,region));


out_com("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg),out_com(rpt_reg,fuel,rt)); 
out_com_esd("EU-27",com_esd,fuel,rt) = sum(rpt_reg$eu27(rpt_reg), out_com_esd(rpt_reg,com_esd,fuel,rt));

out_agr("EU-27",fuel,rt) = sum(rpt_reg$eu27(rpt_reg),out_agr(rpt_reg,fuel,rt)); 

***************************************************************
*** TABLE FINAL ENERGY CONSUMPTION IN RESIDENTIAL
***************************************************************

sets   
    coa_rsd(Commodity) coal in residential /RSDCOA/
    oil_rsd(Commodity) oil products in residential /RSDLPG,RSDOIL/
    bdl_rsd(Commodity) bioliquids in residential /RSDBDL/
    gas_rsd(Commodity) gas in residential /RSDGAS/
    bgs_rsd(Commodity) biogases in residential /RSDBGS/
    elc_rsd(Commodity) electricity in residential /RSDELC/
    bio_rsd(Commodity) biomass and wastes in residential /RSDBIO/
    hth_rsd(Commodity) district heating in residential /RSDHET/
    oth_rsd(Commodity) other energy carriers in residential /RSDGEO,RSDSOL/
    h2_rsd(Commodity)  hydrogen in residential /RSDHH2,RSDGHH2/
    env_rsd(Commodity) environmental heat and cooling /RSDAHT,RSDGHT/
    hta_rsd(Commodity) on-site heat in residential sectors /#hth_com,R_ES-DH-70-SpHeat,R_ES-DH-SpHeat,R_ES-DH-WatHeat,R_ES-FL-SpHeat,R_ES-FL-WatHeat,R_ES-SD-SpHeat,R_ES-SD-WatHeat/
    sh_rsd(Commodity)/R_ES-DH-70-SpHeat,R_ES-DH-SpHeat,R_ES-FL-SpHeat,R_ES-SD-SpHeat/
    wh_rsd(Commodity)/R_ES-DH-WatHeat,R_ES-FL-WatHeat,R_ES-SD-WatHeat/
    rsd_all(Commodity) all fuels in residential sectors /  #coa_rsd,#oil_rsd,#bdl_rsd,#gas_rsd,#bgs_rsd,#elc_rsd,#bio_rsd,#hth_rsd,#h2_rsd,#env_rsd,#oth_rsd/
* Onsite CHP processes 
    chp_rsd_prc(Process) On site CHP processes: fuel input to CHP in residential sectors is excluded from final consumption
*heat pumps
    hp_rsd_prc(Process) heatpump technologies to be conditioned when calculating their shares
    nres_sh_prc(Process)
    nres_wh_prc(Process)
    rsd_dh_prc(process)
    com_dh_prc(process)
    
* Create the table rows 
    rsd_com_fuel(commodity,fuel) /#coa_rsd.coal, #oil_rsd.oil, #bdl_rsd.bioliquids, #gas_rsd.gas, #bgs_rsd.biogas, #elc_rsd.elec, #bio_rsd.biomass, #hth_rsd.heat, #oth_rsd.other,#h2_rsd.h2, #env_rsd.env_heat/
* Residential processes
    rsd_prc(Process) Residential processes excluding on site CHP plants
* Residential energy services
    rsd_dem_com(Commodity) /R_ES-DH-70-SpHeat,R_ES-DH-SpHeat,R_ES-DH-SpCool,R_ES-FL-SpCool,R_ES-FL-SpHeat,R_ES-SD-SpCool,R_ES-SD-SpHeat,R_ES-DH-WatHeat,R_ES-FL-WatHeat,R_ES-SD-WatHeat,R_ES-DH-Cook,R_ES-FL-Cook,R_ES-SD-Cook,RLIG,RREF,RCWA,RCDR,RDWA,ROEL/
    rsd_esd /RSD_DH_SpHeat, RSD_FL_SpHeat, RSD_SD_SpHeat, RSD_DH_SpCool, RSD_FL_SpCool, RSD_SD_SpCool, RSD_DH_Cook, RSD_FL_Cook, RSD_SD_Cook,RSD_DH_WatHeat,RSD_FL_WatHeat,RSD_SD_WatHeat, RSD_Appliances/
    rsd_esd_com(rsd_esd,commodity) /
        RSD_DH_SpHeat.(R_ES-DH-70-SpHeat,R_ES-DH-SpHeat), RSD_FL_SpHeat.R_ES-FL-SpHeat, RSD_SD_SpHeat.R_ES-SD-SpHeat,RSD_DH_SpCool.R_ES-DH-SpCool,RSD_FL_SpCool.R_ES-FL-SpCool,RSD_SD_SpCool.R_ES-SD-SpCool,RSD_DH_Cook.R_ES-DH-Cook,RSD_FL_Cook.R_ES-FL-Cook,RSD_SD_Cook.R_ES-SD-Cook,RSD_DH_WatHeat.R_ES-DH-WatHeat,RSD_FL_WatHeat.R_ES-FL-WatHeat,RSD_SD_WatHeat.R_ES-SD-WatHeat,RSD_Appliances.(RLIG,RREF,RCWA,RCDR,RDWA,ROEL)/
;

parameter
    out_rsd(rpt_reg,fuel,rt) final energy consumption in residential
    out_rsd_h2(rpt_reg,fuel,rt)
    out_rsd_esd(rpt_reg,rsd_esd,fuel,rt) final energy consumption in residential by end use 
    out_rsd_esd_prc(rpt_reg,rsd_esd,process,fuel,rt) final energy consumption in residential by end use 
    test
    test2
    aux_hp_sh(commodity,process,rt,region)
    aux_hp_wh(commodity,process,rt,region)
    aux_nres_sh(commodity,process,rt,region)
    aux_nres_wh(commodity,process,rt,region)
    hp_sh(region,rt)
    hp_wh(region,rt)
    nres_sh(region,rt)
    nres_wh(region,rt)
    
    out_share_hp(region,rt)
    out_rsd_ht_dmd(commodity,rpt_reg,rt)
    out_rsd_wh(region,rt)
    out_rsd_sh(region,rt)
    out_nres_wh(region,rt)
    out_nres_sh(region,rt)
    aux_hta(commodity,process,rt,region)
    hta_rsd_dmd(region,rt)
    
    aux_rsd_dh_sh(commodity,process,rt,region)
    aux_rsd_dh_wh(commodity,process,rt,region)

    aux_nres_dh_sh(commodity,process,rt,region)
    aux_nres_dh_wh(commodity,process,rt,region)


    out_rsd_dh_sh(region,rt)
    out_rsd_dh_wh(region,rt)
    
    out_nres_dh_sh(region,rt)
    out_nres_dh_wh(region,rt)
;

* On-site CHPs to be excluded from final energy consumption 
chp_rsd_prc(dhprd_prc_py) = sum((hta_rsd,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_rsd,dhprd_prc_py,rt,region,v,ts,user_constraint),1);

*Only heatpumps to be included
hp_rsd_prc(hpprd_prc_py) = sum((hta_rsd,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_rsd,hpprd_prc_py,rt,region,v,ts,user_constraint),1);

*nres_sc_prc(elc_nres_sc_py)= sum((hta_com,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_com,elc_nres_sc_py,rt,region,v,ts,user_constraint),1);
nres_sh_prc(elc_nres_sh_py)= sum((hta_com,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_com,elc_nres_sh_py,rt,region,v,ts,user_constraint),1);
nres_wh_prc(elc_nres_wh_py)= sum((hta_com,rt,region,v,ts,user_constraint)$veda_vdd("var_fout",hta_com,elc_nres_wh_py,rt,region,v,ts,user_constraint),1);

* Calculate fuel consumption in residential sectors 
aux_all(process,rt,region)=0; aux_com(commodity,process,rt,region)=0;
aux_hp_sh(commodity,process,rt,region)=0;aux_hp_wh(commodity,process,rt,region)=0;
aux_hta(commodity,process,rt,region)=0;
*aux_nres_sc(commodity,process,rt,region)=0;
aux_nres_sh(commodity,process,rt,region)=0;aux_nres_wh(commodity,process,rt,region)=0;
aux_rsd_dh_sh(commodity,process,rt,region)=0;aux_rsd_dh_wh(commodity,process,rt,region)=0;
aux_nres_dh_sh(commodity,process,rt,region)=0;aux_nres_dh_wh(commodity,process,rt,region)=0;


*aux_com(rsd_all,process,rt,region)$(not chp_rsd_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint));
aux_hp_sh(sh_rsd,process,rt,region)$(hp_rsd_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fout",sh_rsd,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",sh_rsd,process,rt,region,v,ts,user_constraint));
aux_hp_wh(wh_rsd,process,rt,region)$(hp_rsd_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fout",wh_rsd,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",wh_rsd,process,rt,region,v,ts,user_constraint));
aux_hta(hta_rsd,process,rt,region)=sum((v,ts,user_constraint)$veda_vdd("var_fout",hta_rsd,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",hta_rsd,process,rt,region,v,ts,user_constraint));

aux_nres_sh(sh_com,process,rt,region)$(nres_sh_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fout",sh_com,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",sh_com,process,rt,region,v,ts,user_constraint));
aux_nres_wh(wh_com,process,rt,region)$(nres_wh_prc(process)) = sum((v,ts,user_constraint)$veda_vdd("var_fout",wh_com,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",wh_com,process,rt,region,v,ts,user_constraint));

aux_rsd_dh_sh(sh_rsd,rsd_dh_prc_py,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",sh_rsd,rsd_dh_prc_py,rt,region,v,ts,user_constraint), veda_vdd("var_fout",sh_rsd,rsd_dh_prc_py,rt,region,v,ts,user_constraint));
aux_rsd_dh_wh(wh_rsd,rsd_dh_prc_py,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",wh_rsd,rsd_dh_prc_py,rt,region,v,ts,user_constraint), veda_vdd("var_fout",wh_rsd,rsd_dh_prc_py,rt,region,v,ts,user_constraint));

display aux_rsd_dh_sh;
display aux_rsd_dh_wh;

aux_nres_dh_sh(sh_com,com_dh_prc_py,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",sh_com,com_dh_prc_py,rt,region,v,ts,user_constraint), veda_vdd("var_fout",sh_com,com_dh_prc_py,rt,region,v,ts,user_constraint));
aux_nres_dh_wh(wh_com,com_dh_prc_py,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",wh_com,com_dh_prc_py,rt,region,v,ts,user_constraint), veda_vdd("var_fout",wh_com,com_dh_prc_py,rt,region,v,ts,user_constraint));

display aux_nres_dh_sh;
display aux_nres_dh_wh;

aux_dh(dhprd_dh,dhprd_prc,rt,region)= sum((v,ts,user_constraint)$veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fout",dhprd_dh,dhprd_prc,rt,region,v,ts,user_constraint));


*out_rsd_ht_dmd(hta_rsd,rpt_reg,rt)=sum((v,ts,user_constraint)$veda_vdd("var_fout",hta_rsd,process,rt,region,v,ts,user_constraint), veda_vdd("var_fout",hta_rsd,process,rt,region,v,ts,user_constraint));
display aux_hta;

hp_sh(region,rt)=sum((sh_rsd,process),aux_hp_sh(sh_rsd,process,rt,region)$(hp_rsd_prc(process)));
hp_wh(region,rt)=sum((wh_rsd,process),aux_hp_wh(wh_rsd,process,rt,region)$(hp_rsd_prc(process)));

nres_sh(region,rt)=sum((sh_com,process),aux_nres_sh(sh_com,process,rt,region)$(nres_sh_prc(process)));
nres_wh(region,rt)=sum((wh_com,process),aux_nres_wh(wh_com,process,rt,region)$(nres_wh_prc(process)));

*hta_rsd_dmd(region,rt)=sum(hta_rsd,process,aux_hta(hta_rsd,process,rt,region)$(hp_rsd_prc(process)));

out_share_hp(region,rt)=hp_wh(region,rt)/hp_sh(region,rt);
*out_share_hp(rpt_reg,rt)=div0(hp_sh(rpt_reg,rt),hp_wh(rpt_reg,rt))
display out_share_hp;
display aux_hta;
display aux_hp_sh;
display aux_hp_wh;
display nres_sh;
display nres_wh;
aux_com(rsd_all,process,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint));

*aux_h2(commodity,process,rt,region)=sum((v,ts,user_constraint)$veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint), veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint));
out_rsd(rpt_reg,"elec",rt)  = sum((rsd_all,process,region)$(sameas(region,rpt_reg)$rsd_com_fuel(rsd_all,"elec")$aux_com(rsd_all,process,rt,region)),aux_com(rsd_all,process,rt,region));
out_rsd_h2(rpt_reg,"h2",rt)  = sum((rsd_all,process,region)$(sameas(region,rpt_reg)$rsd_com_fuel(rsd_all,"h2")$aux_com(rsd_all,process,rt,region)),aux_com(rsd_all,process,rt,region));
out_rsd_wh(region,rt)=hp_wh(region,rt);
out_rsd_sh(region,rt)=hp_sh(region,rt);

out_nres_sh(region,rt)=nres_sh(region,rt);
out_nres_wh(region,rt)=nres_wh(region,rt);



out_rsd_dh_sh(region,rt)=sum((sh_rsd,process),aux_rsd_dh_sh(sh_rsd,process,rt,region)$(rsd_dh_prc_py(process)));
out_rsd_dh_wh(region,rt)=sum((wh_rsd,process),aux_rsd_dh_wh(wh_rsd,process,rt,region)$(rsd_dh_prc_py(process)));


out_nres_dh_sh(region,rt)=sum((sh_com,process),aux_nres_dh_sh(sh_com,process,rt,region)$(com_dh_prc_py(process)));
out_nres_dh_wh(region,rt)=sum((wh_com,process),aux_nres_dh_wh(wh_com,process,rt,region)$(com_dh_prc_py(process)));



display out_nres_dh_sh;
display out_nres_dh_wh;

test(rpt_reg,process,rt)= sum((region,v,ts,user_constraint,rsd_dem_com)$(sameas(region,rpt_reg)$veda_vdd("var_fout",rsd_dem_com,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",rsd_dem_com,process,rt,region,v,ts,user_constraint));
out_rsd_esd_prc(rpt_reg,rsd_esd,process,"elec",rt)$test(rpt_reg,process,rt)  = sum((rsd_all,region)$(sameas(region,rpt_reg)$rsd_com_fuel(rsd_all,"elec")$aux_com(rsd_all,process,rt,region)$sum((rsd_dem_com,v,ts,user_constraint)$(rsd_esd_com(rsd_esd,rsd_dem_com)$veda_vdd("var_fout",rsd_dem_com,process,rt,region,v,ts,user_constraint)), 1)),aux_com(rsd_all,process,rt,region))*sum((region,v,ts,user_constraint,rsd_dem_com)$(sameas(region,rpt_reg)$rsd_esd_com(rsd_esd,rsd_dem_com)$veda_vdd("var_fout",rsd_dem_com,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",rsd_dem_com,process,rt,region,v,ts,user_constraint))/test(rpt_reg,process,rt);
out_rsd_esd(rpt_reg,rsd_esd,"elec",rt)  = sum(process$out_rsd_esd_prc(rpt_reg,rsd_esd,process,"elec",rt),out_rsd_esd_prc(rpt_reg,rsd_esd,process,"elec",rt) );



rsd_prc(Process)$(not chp_rsd_prc(process))=yes$sum((region,v,rsd_all,rt,ts,user_constraint)$veda_vdd("var_fin",rsd_all,process,rt,region,v,ts,user_constraint), 1);

*hp_wh_rsd_prc(Process)$(hp_rsd_prc(hpprd_prc_py))=yes$sum((region,v,wh_rsd,rt,ts,user_constraint)$veda_vdd("var_fin",wh_rsd,process,rt,region,v,ts,user_constraint), 1);
*hp_sh_rsd_prc(Process)$(hp_rsd_prc(hpprd_prc_py))=yes$sum((region,v,sp_rsd,rt,ts,user_constraint)$veda_vdd("var_fin",sp_rsd,process,rt,region,v,ts,user_constraint), 1);


* correct gas consumption by subtracting e-gases entered into the RSDGAS00 process and add these to the biogases/e-gases category
aux_all(process,rt,region)=0;
aux_all("RSDGAS00",rt,region) = sum((ge_gases_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_gases_com,"RSDGAS00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_gases_com,"RSDGAS00",rt,region,v,ts,user_constraint));
*out_rsd(rpt_reg,"gas",rt) = out_rsd(rpt_reg,"gas",rt) - sum(region$sameas(region,rpt_reg), aux_all("RSDGAS00",rt,region));
*out_rsd(rpt_reg,"biogas",rt) = out_rsd(rpt_reg,"biogas",rt) + sum(region$sameas(region,rpt_reg), aux_all("RSDGAS00",rt,region));

test2(rpt_reg,rt)=1;
*test2(rpt_reg,rt)$out_rsd(rpt_reg,"gas",rt) = sum(rsd_esd, out_rsd_esd(rpt_reg,rsd_esd,"gas",rt))/out_rsd(rpt_reg,"gas",rt);
out_rsd_esd(rpt_reg,rsd_esd,"gas",rt) = out_rsd_esd(rpt_reg,rsd_esd,"gas",rt) *test2(rpt_reg,rt);
test2(rpt_reg,rt)=1;
*test2(rpt_reg,rt)$out_rsd(rpt_reg,"biogas",rt) = sum(rsd_esd, out_rsd_esd(rpt_reg,rsd_esd,"biogas",rt))/out_rsd(rpt_reg,"biogas",rt);
*out_rsd_esd(rpt_reg,rsd_esd,"biogas",rt) = out_rsd_esd(rpt_reg,rsd_esd,"biogas",rt) *test2(rpt_reg,rt);

$ontext
* correct liquids consumption by subtracting e-liquids entered into the COMOIL00 prcess and add them to the bioliquids/e-liquids category
aux_all(process,rt,region)=0;
aux_all("RSDOIL00",rt,region) = sum((ge_liquids_com,v,ts,user_constraint)$veda_vdd("var_fin",ge_liquids_com,"RSDOIL00",rt,region,v,ts,user_constraint), veda_vdd("var_fin",ge_liquids_com,"RSDOIL00",rt,region,v,ts,user_constraint));
out_rsd(rpt_reg,"oil",rt) = out_rsd(rpt_reg,"oil",rt) - sum(region$sameas(region,rpt_reg), aux_all("RSDOIL00",rt,region));
out_rsd(rpt_reg,"bioliquids",rt) = out_rsd(rpt_reg,"bioliquids",rt) + sum(region$sameas(region,rpt_reg), aux_all("RSDOIL00",rt,region));




out_rsd_esd(rpt_reg,rsd_esd,"oil",rt)$(out_rsd(rpt_reg,"oil",rt)+out_rsd(rpt_reg,"bioliquids",rt)) = out_rsd_esd(rpt_reg,rsd_esd,"oil",rt)*out_rsd(rpt_reg,"oil",rt)/(out_rsd(rpt_reg,"oil",rt)+out_rsd(rpt_reg,"bioliquids",rt));
out_rsd_esd(rpt_reg,rsd_esd,"bioliquids",rt)$(out_rsd(rpt_reg,"oil",rt)+out_rsd(rpt_reg,"bioliquids",rt)) = out_rsd_esd(rpt_reg,rsd_esd,"oil",rt)*out_rsd(rpt_reg,"bioliquids",rt)/(out_rsd(rpt_reg,"oil",rt)+out_rsd(rpt_reg,"bioliquids",rt));


$offtext 
*display out_rsd;
display out_rsd_h2;

out_rsd("EU-27","elec",rt) = sum(rpt_reg$eu27(rpt_reg), out_rsd(rpt_reg,"elec",rt)); 
out_rsd_esd("EU-27",rsd_esd,"elec",rt) = sum(rpt_reg$eu27(rpt_reg), out_rsd_esd(rpt_reg,rsd_esd,"elec",rt)); 

$onText
out_ind(rpt_reg,ind_subsec,"h2",rt) = sum((region,h2_ind,h2_indprc,v,ts,user_constraint)$(sameas(region,rpt_reg)$veda_vdd("var_fout",h2_ind,h2_indprc,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",h2_ind,h2_indprc,rt,region,v,ts,user_constraint)) - (sum((h2_ind,region,chp_ind_prc)$(sameas(region,rpt_reg)$aux_com(h2_ind,chp_ind_prc,rt,region)),aux_com(h2_ind,chp_ind_prc,rt,region))/sum((h2_ind,region,process)$(sameas(region,rpt_reg) $aux_com(h2_ind,process,rt,region)),aux_com(h2_ind,process,rt,region)))$sum((h2_ind,region,process)$(sameas(region,rpt_reg) $aux_com(h2_ind,process,rt,region)),aux_com(h2_ind,process,rt,region));
out_ind(rpt_reg,ind_subsec,"h2",rt)/(out_ind(rpt_reg,ind_subsec,"h2",rt)+out_rsd(rpt_reg,"h2",rt))

$offtext 


***************************************************************
*** TABLE FINAL ENERGY CONSUMPTION IN TRANSPORT 
***************************************************************
sets
* transport demands
    dem_tra(Commodity) transport demands /TRai_Frt, TRai_Pas_Conv, TRai_Pas_Hspd, TRai_Pas_Metro,TBunk, TNav, TAvi_Frt_Extra-EU, TAvi_Frt_Intra-EU, TAvi_Pas_Dom, TAvi_Pas_Extra-EU, TAvi_Pas_Intra-EU,TCar, TBus, THDT, TLCV, TMot,TMop/
* domestic transport commodities
    oil_tra(Commodity) domesitc oil productis /TRADST,TRADSTB30,TRADSTSYNG,TRADSTSYNGB30,TRAGSLE85,TRAGSLSP95,TRAGSLSP95E10,TRAHFO,TRAJTK,TRALPG,TRAGSLSYNGE85,TRAGSLSYNGSP95,TRAGSLSYNGSP95E10/
    gas_tra(Commodity) domestic natural gas /TRAGAS/
    bgs_tra(Commodity) domestic biomethanes /TRABGS/
    elc_tra(Commodity) domestic electricity /TRAELC,TRAELC_EV/
    h2_tra(Commodity)  domestic hydrogen /TRAGH2,TRALH2,TRAGGH2,TRALGH2/
* international transport commodities
    oil_int_tra(Commodity) interntional oil products /TRADSTintl, TRAHFOintl,TRAJTKintl, TRADSTintraeuintl, TRAHFOintraeuintl,TRAJTKintraeuintl/
    gas_int_tra(Commodity) international natural gas /TRAGASintl,TRAGASintraeuintl/
    bgs_int_tra(Commodity) international biomethane /TRABGSintl,TRABGSintraeuintl/
    elc_int_tra(Commodity) international electricity /TRAELCintl,TRAELCintraeuintl/
    h2_int_tra(Commodity) international hydrogen /TRALH2Intl,TRALGH2Intl,TRALH2intraeuIntl,TRALGH2intraeuIntl/
*  all transport commodities
    tra_all(Commodity) /#oil_tra, #gas_tra, #bgs_tra, #elc_tra, #h2_tra, #oil_int_tra, #gas_int_tra, #bgs_int_tra, #elc_int_tra, #h2_int_tra/
* Bioliquids (common to domestic and international transport )
    blq_tra(Commodity) bioliquids in transport /BIOBTLFTDSL,BIODME,BIODST,BIOEMHV,BIOHVO,BIOETBE,BIOETHA,BIOMtaH, ISYNGDST,SYNGDST, SYNGKER, ISYNGKER,ISYNGGSL,SYNGGSL /
    blq_prc_tra(Process) blending process for buioliquids /BLDDSL,BLDDSL30,BLDDSLSYNG,BLDDSLSYNG30,BLDDSLintl,BLDJET,BLDJETintl,BLDJETintraeuintl,BLDGSLE85,BLDGSLSP95,BLDGSLSP95E10,BLDGSLSYNGE85,BLDGSLSYNGSP95,BLDGSLSYNGSP95E10/
 
    
$onText
* Create table rows for domestic and international transport 
    tra_dom_fuel(commodity,fuel) table rows for domestic transport / #oil_tra.oil, #blq_tra.bioliquids, #gas_tra.gas, #bgs_tra.biogas, #elc_tra.elec, #h2_tra.h2/
    tra_int_fuel(commodity,fuel) table rows for international transport / #oil_int_tra.oil, #blq_tra.bioliquids, #gas_int_tra.gas, #bgs_int_tra.biogas, #elc_int_tra.elec, #h2_int_tra.h2/

    tra_sec transport reporting sectors /rail_frt,rail_pas,avi_pas_dom,avi_pas_intra,avi_pas_extra,avi_frt_intra,avi_frt_extra,tra_bunk,navi_dom,tra_car,tra_truck,tra_bus,tra_mop/ 
    tra_dem_sec(dem_tra, tra_sec) transport demands to reporting sectors /TRai_Frt.rail_frt, (TRai_Pas_Conv,TRai_Pas_Hspd,TRai_Pas_Metro).rail_pas,TBunk.tra_bunk, TNav.navi_dom,TAvi_Frt_Extra-EU.avi_frt_extra, TAvi_Frt_Intra-EU.avi_frt_intra, TAvi_Pas_Dom.avi_pas_dom, TAvi_Pas_Extra-EU.avi_pas_extra,TAvi_Pas_Intra-EU.avi_pas_intra,TCar.tra_car,TBus.tra_bus, (THDT,TLCV).tra_truck, (TMot,TMop).tra_mop/
    tra_prc_sec(Process, tra_sec) transport processes to sectors
    tra_prc(Process) all transport processes 
;
$offtext

* Create table rows for domestic and international transport 
    tra_dom_fuel(commodity,fuel) table rows for domestic transport /#elc_tra.elec/
    
    tra_sec transport reporting sectors /tra_car,tra_truck,tra_bus,tra_mop/ 
    tra_dem_sec(dem_tra, tra_sec) transport demands to reporting sectors /TCar.tra_car,TBus.tra_bus, (THDT,TLCV).tra_truck, (TMot,TMop).tra_mop/
    tra_prc_sec(Process, tra_sec) transport processes to sectors
    tra_prc(Process) all transport processes 
    ;
 

parameters 
    cf_bioliqs(blq_tra) conversion factor of bioliquids units to PJ
    out_tra(rpt_reg,tra_sec,fuel,rt) final energy consumption in transport sectors
    out_tra_h2(rpt_reg,fuel,rt)
;
* conversion factor for the transport bioliquids from kt to PJ
cf_bioliqs(blq_tra)=1;

cf_bioliqs("BIOBTLFTDSL")=0.044;
cf_bioliqs("BIOHVO")=0.044;cf_bioliqs("BIOEMHV")=0.0374;cf_bioliqs("BIOETBE")=0.0363;cf_bioliqs("BIOETHA")=0.0268;
* Select proceses per transport subsector 
tra_prc_sec(Process, tra_sec)=yes$sum((dem_tra,rt,region,v,ts,user_constraint)$(tra_dem_sec(dem_tra, tra_sec) $veda_vdd("var_fout",dem_tra,process,rt,region,v,ts,user_constraint) ),1);
tra_prc(Process) =yes$sum(tra_sec$tra_prc_sec(Process,tra_sec),1);

* Calculate bioliquid consumption (total)
aux_all(process,rt,region)=0;
aux_all(blq_prc_tra,rt,region) = sum((blq_tra,v,ts,user_constraint)$veda_vdd("var_fin",blq_tra,blq_prc_tra,rt,region,v,ts,user_constraint),cf_bioliqs(blq_tra)*veda_vdd("var_fin",blq_tra,blq_prc_tra,rt,region,v,ts,user_constraint));

* Correct sectoral consumption for biofuels
aux_com2(commodity,process,rt,region)=0;
aux_com2(tra_all,blq_prc_tra,rt,region)$(oil_int_tra(tra_all) or oil_tra(tra_all)) = sum((v,ts,user_constraint)$veda_vdd("var_fout",tra_all,blq_prc_tra,rt,region,v,ts,user_constraint),veda_vdd("var_fout",tra_all,blq_prc_tra,rt,region,v,ts,user_constraint));
out_tra(rpt_reg,tra_sec,"bioliquids",rt) = sum((tra_all,blq_prc_tra,region)$(sameas(region,rpt_reg) $(oil_int_tra(tra_all) or oil_tra(tra_all)) $aux_com2(tra_all,blq_prc_tra,rt,region)), aux_all(blq_prc_tra,rt,region)/aux_com2(tra_all,blq_prc_tra,rt,region) * sum((tra_prc)$tra_prc_sec(tra_prc,tra_sec),aux_com(tra_all,tra_prc,rt,region)));
out_tra(rpt_reg,tra_sec,"oil",rt) = out_tra(rpt_reg,tra_sec,"oil",rt) - out_tra(rpt_reg,tra_sec,"bioliquids",rt);

parameters 
    out_tra(rpt_reg,tra_sec,fuel,rt) final energy consumption in transport sectors 
;

* Select proceses per transport subsector 
tra_prc_sec(Process, tra_sec)=yes$sum((dem_tra,rt,region,v,ts,user_constraint)$(tra_dem_sec(dem_tra, tra_sec) $veda_vdd("var_fout",dem_tra,process,rt,region,v,ts,user_constraint) ),1);
tra_prc(Process) =yes$sum(tra_sec$tra_prc_sec(Process,tra_sec),1);


* Calculate consumption per process and commodity
aux_com(commodity,process,rt,region)=0;
aux_com(tra_all,tra_prc,rt,region) = sum((v,ts,user_constraint)$veda_vdd("var_fin",tra_all,tra_prc,rt,region,v,ts,user_constraint), veda_vdd("var_fin",tra_all,tra_prc,rt,region,v,ts,user_constraint));


out_tra(rpt_reg,tra_sec,"elec",rt) = sum((tra_all,tra_prc,region)$(sameas(region,rpt_reg) $(tra_dom_fuel(tra_all,"elec")) $tra_prc_sec(tra_prc,tra_sec)), aux_com(tra_all,tra_prc,rt,region));
out_tra_h2(rpt_reg,"h2",rt)  = sum((tra_all,process,region)$(sameas(region,rpt_reg)$tra_dom_fuel(tra_all,"h2")$aux_com(tra_all,process,rt,region)),aux_com(tra_all,process,rt,region));

display out_tra_h2;

out_tra("EU-27",tra_sec,fuel,rt) = sum(rpt_reg$eu27(rpt_reg), out_tra(rpt_reg,tra_sec,fuel,rt));


***************************************************************
*** TABLE CO2 EMISSIONS BY SECTOR
***************************************************************
Sets    
    elc_co2(commodity) co2 emissions in power generation /ELCCO2I,ELCCO2N, ELCCO2P/
    ind_co2(commodity) co2 emissions in industry /INDCO2N, INDCO2P/
    ind_sco2(commodity) sequestrated co2 emissions in industry /INDSCO2GN,INDSCO2N,INDSCO2P/
    com_co2(commodity) co2 emissions in services and aggriculture /COMCO2N/
    agr_co2(commodity) co2 emissions in aggriculture /AGRCO2N/
    rsd_co2(commodity) co2 emissions in residential /RSDCO2N/
*    tra_dom_co2(commodity) co2 emissions in transport domestic /SE_TRACO2N, SE_TRACO2P/
    tra_dom_co2(commodity) co2 emissions in transport domestic /TRACO2N, SE_TRACO2P/
    oth_co2(commodity) co2 emissions in the other upstream sector /SUPCO2N, SUPCO2P/
*    tra_int_co2(commodity) co2 emissions in international aviation and bunkers/SE_TRACO2NIntl/
    tra_int_co2(commodity) co2 emissions in international aviation and bunkers/TRACO2NIntl/
    tot_co2(commodity) total co2 emissions without internatinal aviation /totco2/
*    dac (process) direct air capture / SNK_DAC,SNK_DAC_GAS,SNK_DAC_GAS_LowAF,SNK_DAC_LowAF/
    dac (process) direct air capture / SNK_DAC,SNK_DAC_GAS/
*    atm(process) synthetic fuels with direct air capture /S_CCUS_ATM,S_CCUS_ATM_LowAF,S_CCUS_ATM_MeOH,S_CCUS_ATM_MeOH_LowAF/
    lulucf(process) lulucf removals /SINKAFE/
    elc_ccs(process) co2 capture from electricity and heat /STORAGE_ELCS/
    ind_ccs(process) co2 capture from industrial processes /STORAGE_INDS,STORAGE_COMS/
    oth_ccs(process) co2 capture from hydrogen and other upstream sector  /STORAGE_SUPS/
    sectors /co2_elc, co2_ind, co2_ser, co2_agr,co2_res, co2_tra_dom, co2_tot, ccs_dac, ccs_elc, ccs_ind, ccs_oth, co2_tra_int_avi, co2_tra_int_navi,lulucf, ind_chp, ind_blf, ind_iis,ind_inf,ind_ich,ind_inm,ind_ipp,ind_ioi,ind_ccschp,ind_ccsblf,ind_ccsiis,ind_ccsinf,ind_ccsich,ind_ccsinm,ind_ccsipp,ind_ccsioi,co2_oth, co2_tra_int/
    sectors_wimby /co2_elc, co2_ind, co2_ser, co2_agr,co2_res, co2_tra_dom, co2_tot/
    co2_com_sectors(commodity,sectors) /#elc_co2.co2_elc,#ind_co2.co2_ind,#agr_co2.co2_agr,#com_co2.co2_ser,#rsd_co2.co2_res,#tra_dom_co2.co2_tra_dom,#oth_co2.co2_oth, #tra_int_co2.co2_tra_int, #tot_co2.co2_tot/
    co2_com_sectors_wimby(commodity,sectors)/#elc_co2.co2_elc,#ind_co2.co2_ind,#agr_co2.co2_agr,#com_co2.co2_ser,#rsd_co2.co2_res,#tra_dom_co2.co2_tra_dom, #tot_co2.co2_tot/
    co2_prc_sectors(process,sectors) /#dac.ccs_dac, #elc_ccs.ccs_elc, #ind_ccs.ccs_ind, #oth_ccs.ccs_oth, #lulucf.lulucf/
    co2_prc_ind_sectors(process,sectors)
    co2_prc_ccsind_sectors(process,sectors)
;
co2_prc_ind_sectors(iis_prc,"ind_iis")=yes;co2_prc_ind_sectors(inf_prc,"ind_inf")=yes;co2_prc_ind_sectors(ich_prc,"ind_ich")=yes;co2_prc_ind_sectors(ipp_prc,"ind_ipp")=yes;co2_prc_ind_sectors(inm_prc,"ind_inm")=yes;co2_prc_ind_sectors(ioi_prc,"ind_ioi")=yes;co2_prc_ind_sectors(chp_ind_prc,"ind_chp")=yes;co2_prc_ind_sectors(blf_prc,"ind_blf")=yes;
co2_prc_ccsind_sectors(iis_prc,"ind_ccsiis")=yes;co2_prc_ccsind_sectors(inf_prc,"ind_ccsinf")=yes;co2_prc_ccsind_sectors(ich_prc,"ind_ccsich")=yes;co2_prc_ccsind_sectors(ipp_prc,"ind_ccsipp")=yes;co2_prc_ccsind_sectors(inm_prc,"ind_ccsinm")=yes;co2_prc_ccsind_sectors(ioi_prc,"ind_ccsioi")=yes;co2_prc_ccsind_sectors(chp_ind_prc,"ind_ccschp")=yes;co2_prc_ccsind_sectors(blf_prc,"ind_ccsblf")=yes;

parameter
    out_co2(rpt_reg,sectors,rt) co2 emissions by sector
    out_co2_intra_eu(rpt_reg,rt) CO2 emissions in intra-EU aviation

*    atm_co2(rpt_reg,rt) CO2 capture in fuel synthesis with atmospheric CO2
;    
* atm_co2(rpt_reg,rt) = sum((atm,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_fin","TOTCO2",atm,rt,region,v,ts,user_constraint)),veda_vdd("var_fin","TOTCO2",atm,rt,region,v,ts,user_constraint));

out_co2(rpt_reg,sectors,rt)$sectors_wimby(sectors) = sum((commodity,region,ts)$(sameas(region, rpt_reg)$co2_com_sectors(commodity,sectors)$veda_vdd("var_comnet",commodity,"-",rt,region,"-",ts,"-")),veda_vdd("var_comnet",commodity,"-",rt,region,"-",ts,"-"))+
                              sum((process,commodity,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$co2_prc_sectors(process,sectors)$veda_vdd("var_act",commodity,process,rt,region,v,ts,user_constraint)),veda_vdd("var_act",commodity,process,rt,region,v,ts,user_constraint))+
                              sum((process,ind_co2,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$co2_prc_ind_sectors(process,sectors)$veda_vdd("var_fout",ind_co2,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",ind_co2,process,rt,region,v,ts,user_constraint))+
                              sum((process,ind_sco2,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$co2_prc_ccsind_sectors(process,sectors)$veda_vdd("var_fout",ind_sco2,process,rt,region,v,ts,user_constraint)),veda_vdd("var_fout",ind_sco2,process,rt,region,v,ts,user_constraint))



* + atm_co2(rpt_reg,rt) $sameas(sectors,"ccs_oth") -  atm_co2(rpt_reg,rt) $sameas(sectors,"co2_oth") ;
;

out_co2(rpt_reg,"ccs_dac",rt) = sum((dac,region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_act","-",dac,rt,region,v,ts,user_constraint)),veda_vdd("var_act","-",dac,rt,region,v,ts,user_constraint));


*out_co2(rpt_reg,"co2_tra_int_avi",rt)=sum((region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_fout","SE_TRACO2NIntl","BLDJETintl",rt,region,v,ts,user_constraint)),veda_vdd("var_fout","SE_TRACO2NIntl","BLDJETintl",rt,region,v,ts,user_constraint));    
out_co2(rpt_reg,"co2_tra_int_avi",rt)=sum((region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_fout","TRACO2NIntl","BLDJETintl",rt,region,v,ts,user_constraint)),veda_vdd("var_fout","TRACO2NIntl","BLDJETintl",rt,region,v,ts,user_constraint))+
                                      sum((region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_fout","TRACO2NIntl","BLDJETintraeuintl",rt,region,v,ts,user_constraint)),veda_vdd("var_fout","TRACO2NIntl","BLDJETintraeuintl",rt,region,v,ts,user_constraint));


out_co2_intra_eu(rpt_reg,rt)=sum((region,v,ts,user_constraint)$(sameas(region, rpt_reg)$veda_vdd("var_fout","TRACO2NIntl","BLDJETintraeuintl",rt,region,v,ts,user_constraint)),veda_vdd("var_fout","TRACO2NIntl","BLDJETintraeuintl",rt,region,v,ts,user_constraint));

out_co2_intra_eu("EU-27",rt)= sum(rpt_reg$eu27(rpt_reg), out_co2_intra_eu(rpt_reg,rt)); 

out_co2(rpt_reg,"co2_tra_int_navi",rt) = out_co2(rpt_reg,"co2_tra_int",rt)-out_co2(rpt_reg,"co2_tra_int_avi",rt);

out_co2("EU-27",sectors,rt) = sum(rpt_reg$eu27(rpt_reg), out_co2(rpt_reg,sectors,rt)); 
 


Parameter
share(rpt_reg,fuel,rt) share of final consumption of doemstically-produced hydrogen for industry among other sectors
out_indh2_elc(rpt_reg,fuel,rt)
share_h2(rpt_reg,rt)
;

share(rpt_reg,"h2",rt)=div0(out_ind_h2(rpt_reg,"h2",rt),out_rsd_h2(rpt_reg,"h2",rt)+out_ind_h2(rpt_reg,"h2",rt)+out_com_h2(rpt_reg,"h2",rt)+out_agr_h2(rpt_reg,"h2",rt)+out_tra_h2(rpt_reg,"h2",rt));
display share;

*out_indh2_elc(region,fuel,rt)=aux_h2elc(region,"h2",rt)*share(region,"h2",rt);


*out_indh2_elc(commodity,process,rt,region)=sum(commodity,aux_h2_elc(commodity,process,rt,region));
*display out_indh2_elc;


$onText
*************************************
*** TABLE Energy System Costs
*************************************
set cost_sectors sectors for reporting the costs /ele, eleTD, h2, h2TD, syn, synTD, iis,inf,ich,inm,ipp,ioi,indTD,com,comTD,rsd,rsdTD,agr,agrTD,tra_car,tra_truck,tra_bus,tra_mop, rail_frt, rail_pas, avi_pas_dom,avi_pas_intra,avi_pas_extra,avi_frt_intra, avi_frt_extra,tra_bunk, navi_dom, traTD, nimp_coa,nimp_oil,nimp_gas,nimp_bio,nimp_elc,nimp_h2,nimp_e_fuels,oth/
    cost_elc_sectors(cost_sectors) /ele, eleTD/
    cost_h2_sectors(cost_sectors) /h2, h2TD/
    cost_syn_sectors(cost_sectors) /syn, synTD/
    cost_process_sectors(process,cost_sectors) mapping of processes to sectors for the reporting
    cost_attr(attribute) cost attributes /Cost_act ,Cost_com, Cost_Dec, Cost_comx ,Cost_fixx,Cost_flo,Cost_flox,Cost_fom,Cost_inv,Cost_invx,Cost_npv,Cost_salv,Cost_ire/
    cost_capex(attribute) cost attributes related to capex /Cost_inv,Cost_Dec/
    cost_opex(attribute) cost attributes related to opex /Cost_act,Cost_flo,Cost_fom,Cost_com/
    cost_opex_act(attribute) OPEX on activity of a process /Cost_act/
    cost_opex_flo(attribute) OPEX on the flow of a process /Cost_flo,Cost_com/
    cost_opex_fix(attribute) OPEX on the fixed cost of a process /Cost_fom/
    cost_capex_tax(attribute) cost attributes related to capital taxes and subsidies /Cost_invx/
    cost_opex_tax(attribute) cost attributes related to opex taxes and subsidies /Cost_comx,Cost_fixx,Cost_flox/
    cost_ire(attribute) cost attributes related to interregional trade /cost_ire/
    cost_other(attribute) /Cost_npv,Cost_salv/
    cost_elements/capex, opex, opex_act, opex_flo, opex_fix, capex_tax, opex_tax, cost_ire, cost_other/
    cost_elements_attributes(cost_elements, cost_attr)/capex.#cost_capex, opex.#cost_opex, capex_tax.#cost_capex_tax, opex_tax.#cost_opex_tax, cost_ire.#cost_ire,cost_other.#cost_other,opex_act.#cost_opex_act,opex_flo.#cost_opex_flo,opex_fix.#cost_opex_fix/
    reg_acost(dim3, cost_elements) /FIX.opex,FIXX.opex_tax,INV.capex,INVX.capex_tax,IRE.cost_ire,VAR.opex,VARX.opex_tax/
;

execute "gdxxrw.exe results_template.xlsb o=cost_sectors%SCENARIO%.gdx set=cost_process_sectors rng=Sector_mapping!B3 dim=2 rdim=2"
execute_load "cost_sectors%SCENARIO%.gdx",cost_process_sectors

set pri_prc_fuel(process,fuel) primary input fuel of a process;

parameter
    out_system_cost(rpt_reg,cost_sectors,cost_elements,rt) output of the system costs per sector
    out_reg_cost(rpt_reg, cost_elements, rt) total annual cost per country
    out_intrate_constr(rpt_reg,cost_sectors,rt) payments for interest rates in construction

    system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt) output of the system costs per process and sector
    out_system_elc_cost(rpt_reg,fuel,cost_elements,rt) output of the system costs of the electricity sector
    test_elc_cost(rpt_reg,process,fuel,cost_elements,rt) output of the system costs of the electricity sector

    out_system_dh_cost(rpt_reg,fuel,cost_elements,rt) output of the system costs of the district heating sector
    out_system_h2_cost(rpt_reg,fuel,cost_elements,rt)  output of the system costs of the hydrogen production sector
    test_h2_cost(rpt_reg,process,fuel,cost_elements,rt) output of the system costs of the hydrogen production sector

    out_system_syn_cost(rpt_reg,synfuels_types,cost_elements,rt) output of the system cost for synfuel prodution (biofuels and e-fuels)
    test_syn_cost(rpt_reg,process,synfuels_types,cost_elements,rt) output of the system cost for synfuel production by process 

;
out_system_cost(rpt_reg,cost_sectors,cost_elements,rt) = sum((cost_attr,commodity,process,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$cost_process_sectors(process,cost_sectors)$cost_elements_attributes(cost_elements, cost_attr)$veda_vdd(cost_attr,commodity,process,rt,region,v,ts,userconstraint)),veda_vdd(cost_attr,commodity,process,rt,region,v,ts,userconstraint));
out_system_cost(rpt_reg, "oth","opex", rt)= sum((commodity,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$veda_vdd("Cost_com",commodity,"-",rt,region,v,ts,userconstraint)),veda_vdd("Cost_com",commodity,"-",rt,region,v,ts,userconstraint));
out_system_cost(rpt_reg, "oth","opex_tax", rt)= sum((commodity,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$veda_vdd("Cost_comx",commodity,"-",rt,region,v,ts,userconstraint)),veda_vdd("Cost_comx",commodity,"-",rt,region,v,ts,userconstraint));
out_system_cost("EU-27",cost_sectors,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg), out_system_cost(rpt_reg,cost_sectors,cost_elements,rt)); 
* System ocst by process and sector
system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt) =  sum((cost_attr,commodity,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$cost_process_sectors(process,cost_sectors)$cost_elements_attributes(cost_elements, cost_attr)$veda_vdd(cost_attr,commodity,process,rt,region,v,ts,userconstraint)),veda_vdd(cost_attr,commodity,process,rt,region,v,ts,userconstraint));
system_prc_cost("EU-27",process, cost_sectors,cost_elements,rt) =  sum(rpt_reg$eu27(rpt_reg), system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt) );

* Electricity sector detailed costs by fuel 
out_system_elc_cost(rpt_reg,fuel,cost_elements,rt) = sum((region,process,cost_sectors)$(sameas(region, rpt_reg)$cost_elc_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$sum(rt2,elc_prc(region,process,fuel,rt2))$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
out_system_elc_cost("EU-27",fuel,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),out_system_elc_cost(rpt_reg,fuel,cost_elements,rt));
test_elc_cost(rpt_reg,process,fuel,cost_elements,rt) = sum((region,cost_sectors)$(sameas(region, rpt_reg)$cost_elc_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$sum(rt2,elc_prc(region,process,fuel,rt2))$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
test_elc_cost("EU-27",process,fuel,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),test_elc_cost(rpt_reg,process,fuel,cost_elements,rt) );

* District heating sector detailed costs by fuel
out_system_dh_cost(rpt_reg,fuel,cost_elements,rt) = sum((region,process,cost_sectors)$(sameas(region, rpt_reg)$cost_elc_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$dhprd_prc(process)$out_dhprod_prc(rpt_reg,process,fuel,rt)$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
out_system_dh_cost("EU-27",fuel,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),out_system_dh_cost(rpt_reg,fuel,cost_elements,rt));

* Hydrogen production sector detailed costs by fuel
pri_prc_fuel(h2prd_prc,fuel)$(not h2prd_ccs_prc(h2prd_prc)) = sum((rpt_reg,rt)$out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt),out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt)=smax(fuel2$out_h2prod_prc(rpt_reg,h2prd_prc,fuel2,rt), out_h2prod_prc(rpt_reg,h2prd_prc,fuel2,rt)));
pri_prc_fuel(h2prd_prc,fuel)$(h2prd_ccs_prc(h2prd_prc)) = sum((rpt_reg,rt)$out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt),out_h2prod_prc(rpt_reg,h2prd_prc,fuel,rt)=smax(fuel2$out_h2prod_prc(rpt_reg,h2prd_prc,fuel2,rt), out_h2prod_prc(rpt_reg,h2prd_prc,fuel2,rt)));

out_system_h2_cost(rpt_reg,fuel,cost_elements,rt) = sum((region,process,cost_sectors)$(sameas(region, rpt_reg)$cost_h2_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$h2prd_prc(process)$pri_prc_fuel(process,fuel)$out_h2prod_prc(rpt_reg,process,fuel,rt)$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
out_system_h2_cost("EU-27",fuel,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),out_system_h2_cost(rpt_reg,fuel,cost_elements,rt));
test_h2_cost(rpt_reg,process,fuel,cost_elements,rt) = sum((region,cost_sectors)$(sameas(region, rpt_reg)$cost_h2_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$h2prd_prc(process)$out_h2prod_prc(rpt_reg,process,fuel,rt)$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
test_h2_cost("EU-27",process,fuel,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),test_h2_cost(rpt_reg,process,fuel,cost_elements,rt) );

* Synthetic fuels detailed costs by fuel type
out_system_syn_cost(rpt_reg,synfuels_types,cost_elements,rt) = sum((region,process,cost_sectors)$(sameas(region, rpt_reg)$cost_syn_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$synfuels_prc_types(synfuels_types,process)$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
out_system_syn_cost("EU-27",synfuels_types,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),out_system_syn_cost(rpt_reg,synfuels_types,cost_elements,rt));
test_syn_cost(rpt_reg,process,synfuels_types,cost_elements,rt) = sum((region,cost_sectors)$(sameas(region, rpt_reg)$cost_syn_sectors(cost_sectors)$cost_process_sectors(process,cost_sectors)$synfuels_prc_types(synfuels_types,process)$system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt)),system_prc_cost(rpt_reg,process, cost_sectors,cost_elements,rt));
test_syn_cost("EU-27",process,synfuels_types,cost_elements,rt) = sum(rpt_reg$eu27(rpt_reg),test_syn_cost(rpt_reg,process,synfuels_types,cost_elements,rt));

* Total regional cost 
out_reg_cost(rpt_reg, cost_elements, rt)= sum((commodity,process,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$reg_acost(userconstraint, cost_elements)$veda_vdd("Reg_ACost",commodity,process,rt,region,v,ts,userconstraint)),veda_vdd("Reg_Acost",commodity,process,rt,region,v,ts,userconstraint));
out_reg_cost("EU-27", cost_elements, rt)= sum(rpt_reg$eu27(rpt_reg), out_reg_cost(rpt_reg, cost_elements, rt)); 
* Hurdle rate costs 
out_intrate_constr(rpt_reg,cost_sectors,rt) = sum((commodity,process,region,v,ts)$(sameas(region, rpt_reg)$cost_process_sectors(process,cost_sectors)$veda_vdd("cost_inv",commodity,process,rt,region,v,ts,"inv+")),veda_vdd("cost_inv",commodity,process,rt,region,v,ts,"inv+"));
out_intrate_constr("EU-27",cost_sectors,rt) = sum(rpt_reg$eu27(rpt_reg),out_intrate_constr(rpt_reg,cost_sectors,rt));

*************************************
*** EU ETS CO2 price (average)
*************************************

set etsco2(commodity) EU ETS emissions commodities /ETSCO2/;

parameter out_ETSCO2(etsco2,rt) average EU ETS price in EUR15 per ton of CO2;

out_ETSCO2(etsco2,rt)$sum((region,ts)$veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-"), veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-")) = sum((region,ts)$veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-"), veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-")*(-veda_vdd("EQ_combalM",etsco2,"-",rt,region,"-",ts,"-")*1000))/sum((region,ts)$veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-"), veda_vdd("VAR_comnet",etsco2,"-",rt,region,"-",ts,"-"));

*************************************
*** ELECTRICITY PRODUCTION CAPACITIES
*************************************
set invalid_eclprodcap(process) processes not to be included in this report /BRF2_BTLFTDSL,BRF2_BTLFTDSL_CCS, BRF2_ETHLGC,BRF2_ETHLGC_CCS,R_ES-CHP-DH_GAS01,R_ES-CHP-DH_GAS02,R_ES-CHP-DH_GAS03,R_ES-CHP-DH_GAS04,R_ES-CHP-DH_HH201,R_ES-CHP-DH_OIL01,R_ES-CHP-DH_OIL02,R_ES-CHP-DH-70_GAS01,R_ES-CHP-DH-70_GAS02,R_ES-CHP-DH-70_GAS03,R_ES-CHP-DH-70_GAS04,R_ES-CHP-DH-70_HH201,R_ES-CHP-DH-70_OIL01,R_ES-CHP-DH-70_OIL02,R_ES-CHP-FL_GAS01,R_ES-CHP-FL_GAS02,R_ES-CHP-FL_GAS03,R_ES-CHP-FL_GAS04,R_ES-CHP-FL_HH201,R_ES-CHP-FL_OIL01,R_ES-CHP-FL_OIL02,R_ES-CHP-SD_GAS01,R_ES-CHP-SD_GAS02,R_ES-CHP-SD_GAS03,R_ES-CHP-SD_GAS04,R_ES-CHP-SD_HH201,R_ES-CHP-SD_OIL01,R_ES-CHP-SD_OIL02/;


parameter
    out_elcprodcap(rpt_reg,process,fuel,rt) electrcicity production by process and fuel (internal parameter)
;

out_elcprodcap(rpt_reg,eprd_prc,fuel,rt) = sum((region,v,ts,UserConstraint)$(sameas(region, rpt_reg)$(not invalid_eclprodcap(eprd_prc))$eprd_prccap_fuels(eprd_prc,fuel)$veda_vdd("var_cap","-",eprd_prc,rt,Region,v,ts,UserConstraint)),veda_vdd("var_cap","-",eprd_prc,rt,Region,v,ts,UserConstraint));

out_elcprodcap("EU-27",eprd_prc,fuel,rt) = sum(rpt_reg$eu27(rpt_reg), out_elcprodcap(rpt_reg,eprd_prc,fuel,rt)); 


*************************************
*** VEHICLE STOCK
*************************************
set
    veh_types /
* cars    
        car_gasoline, car_diesel, car_other, car_electric, car_hydrogen
* LCV
        lcv_gasoline, lcv_diesel, lcv_other, lcv_electric, lcv_hydrogen
* Trucks
        trucks_gasoline, trucks_diesel, trucks_other, trucks_electric, trucks_hydrogen/
        
    tra_veh_types(process, veh_types)
;

tra_veh_types(tra_cargsl_py,"car_gasoline")=yes;
tra_veh_types(tra_cardsl_py,"car_diesel")=yes;
tra_veh_types(tra_carlpg_py,"car_other")=yes;
tra_veh_types(tra_carcng_py,"car_other")=yes;
tra_veh_types(tra_carelc_py,"car_electric")=yes;
tra_veh_types(tra_carhh2_py,"car_hydrogen")=yes;
tra_veh_types(tra_lcvcng_py,"lcv_other")=yes;  
tra_veh_types(tra_lcvdsl_py,"lcv_diesel")=yes;    
tra_veh_types(tra_lcvelc_py,"lcv_electric")=yes;     
tra_veh_types(tra_lcvgas_py,"lcv_gasoline")=yes;     
tra_veh_types(tra_lcvhh2_py,"lcv_hydrogen")=yes;  
tra_veh_types(tra_lcvlpg_py,"lcv_other")=yes;  


tra_veh_types(tra_hdtcng_py,"trucks_other") = yes;
tra_veh_types(tra_hdtdsl_py,"trucks_diesel") = yes;
tra_veh_types(tra_hdtelc_py,"trucks_electric") = yes;
tra_veh_types(tra_hdthh2_py,"trucks_hydrogen") = yes;
;


parameter
    out_veh_stock(rpt_reg,veh_types,rt) vehicle stock by vehicle in transport sector ;

out_veh_stock(rpt_reg,veh_types,rt) = sum((process,region,v,ts,UserConstraint)$(sameas(region, rpt_reg)$tra_veh_types(process, veh_types)$veda_vdd("var_cap","-",process,rt,Region,v,ts,UserConstraint)),veda_vdd("var_cap","-",process,rt,Region,v,ts,UserConstraint));

out_veh_stock("EU-27",veh_types,rt) = sum(rpt_reg$eu27(rpt_reg), out_veh_stock(rpt_reg,veh_types,rt));

*************************************
*** SPLIT OF BIOMASS AND WASTE CONSUMPTION BY SECTOR
*************************************

set wood(commodity) /BIOWOO/
    waste(commodity)/BIOMUN,BIOSLU/
    biowaste /biomass,waste/
    biowaste_com(biowaste,commodity) /biomass.#wood, waste.#waste/
    bio_prc(process) fuel tech processes /AGRBIO00,COMBIO00,ELCWOO00,INDBIO00,RSDBIO00,SUPBIO00,ELCSLU00,INDSLU00,ELCMUN00,INDMUN00,BWOOGAS110,BSLUGAS101,SBIO_G_H2GC01,SBIO_G_H2GCC01,SBIO_G_H2GD01,SBIO_G_H2RC01,SBIOH2GC01,SBIOH2GCC01,SBIOH2GD01,SBIOH2RC01/
    bio_sect sectors for biomass and waste consumption /agr, com, elc, ind, rsd, syn, h2, oth/
    bio_sect_prc(bio_sect,process) sectors to process mapping /agr.AGRBIO00, com.COMBIO00, elc.(ELCWOO00,ELCSLU00,ELCMUN00), ind.(INDBIO00,INDMUN00,INDSLU00), rsd.RSDBIO00, syn.(BSLUGAS101,BWOOGAS110), h2.(SBIO_G_H2GC01,SBIO_G_H2GCC01,SBIO_G_H2GD01,SBIO_G_H2RC01,SBIOH2GC01,SBIOH2GCC01,SBIOH2GD01,SBIOH2RC01), oth.SUPBIO00/
;

parameter out_biowaste(rpt_reg,bio_sect,biowaste,rt) consumption of biomass and waste per sector ;

out_biowaste(rpt_reg,bio_sect,biowaste,rt) = sum((commodity,process,region,v,ts,userconstraint)$(sameas(region, rpt_reg)$biowaste_com(biowaste,commodity)$bio_prc(process)$bio_sect_prc(bio_sect,process)$veda_vdd("var_fin",commodity,process,rt,Region,v,ts,UserConstraint)), veda_vdd("var_fin",commodity,process,rt,Region,v,ts,UserConstraint));

out_biowaste("EU-27",bio_sect,biowaste,rt) =  sum(rpt_reg$eu27(rpt_reg), out_biowaste(rpt_reg,bio_sect,biowaste,rt));

$OffText
*************************************
*** EXPORT RESULTS TO EXCEL
*************************************



$onText

par=out_nimp                  rng=out_nimp!a3                    rdim=2 cdim=1
par=out_elprod                rng=out_elprod!a3                  rdim=2 cdim=1
par=out_h2prod                rng=out_h2prod!a3                  rdim=2 cdim=1
par=out_synfuels              rng=out_synfuels!a3                rdim=2 cdim=1
par=out_dhprod                rng=out_lthprod!a3                 rdim=2 cdim=1
par=out_nen                   rng=out_nen!a3                     rdim=1 cdim=1
par= out_system_cost          rng=out_system_cost!a3             rdim=3 cdim=1
par=out_agr                   rng=out_agr!a3                     rdim=2 cdim=1
par=out_co2_intra_eu          rng=out_co2_intra_eu!a3            rdim=1 cdim=1
$offText
$onecho>out%SCENARIO%.txt
par=out_pprod                 rng=out_pprod!a3                   rdim=2 cdim=1
par=out_ind                   rng=out_ind!a3                     rdim=3 cdim=1
par=out_com                   rng=out_com!a3                     rdim=2 cdim=1
par=out_rsd                   rng=out_rsd!a3                     rdim=2 cdim=1
par= out_com_esd              rng=out_com_esd!a3                 rdim=3 cdim=1
par= out_rsd_esd              rng=out_rsd_esd!a3                 rdim=3 cdim=1
par=out_rsd_sh                rng=out_rsd_sh!a3                  rdim=1 cdim=1
par=out_rsd_wh                rng=out_rsd_wh!a3                  rdim=1 cdim=1
par=out_nres_sh               rng=out_nres_sh!a3                 rdim=1 cdim=1
par=out_nres_wh               rng=out_nres_wh!a3                 rdim=1 cdim=1
par=out_tra                   rng=out_tra!a3                     rdim=3 cdim=1
par=out_co2                   rng=out_co2!a3                     rdim=2 cdim=1
par=out_h2elc                 rng=out_h2elc!a3                   rdim=2 cdim=1
par=in_synfuels               rng=in_synfuels!a3                 rdim=2 cdim=1
par=out_share_dh              rng=out_share_dh!a3                rdim=1 cdim=1
par=out_rsd_dh_sh             rng=out_rsd_dh_sh!a3               rdim=1 cdim=1
par=out_rsd_dh_wh             rng=out_rsd_dh_wh!a3               rdim=1 cdim=1
par=out_nres_dh_sh            rng=out_nres_dh_sh!a3              rdim=1 cdim=1
par=out_nres_dh_wh            rng=out_nres_dh_wh!a3              rdim=1 cdim=1


$offecho 
$onText

par= out_reg_cost             rng=out_reg_cost!a3                rdim=2 cdim=1
par=out_ETSCO2                rng=out_ETSCO2!a3                  rdim=1 cdim=1  
par=out_elcprodcap            rng=out_elcprodcap!a3              rdim=3 cdim=1
par=out_veh_stock             rng=out_veh_stock!a3               rdim=2 cdim=1
par=out_biowaste              rng=out_biowaste!a3                rdim=3 cdim=1
par=out_intrate_constr        rng=out_intrate_constr!a3          rdim=2 cdim=1
par=in_elprod                 rng=in_elprod!a3                   rdim=2 cdim=1
par=in_h2prod                 rng=in_h2prod!a3                   rdim=2 cdim=1
par=in_dhprod                 rng=in_dhprod!a3                   rdim=2 cdim=1
par=out_system_elc_cost       rng=out_system_elc_cost!a3         rdim=3 cdim=1
par=out_system_dh_cost        rng=out_system_dh_cost!a3          rdim=3 cdim=1
par=out_system_h2_cost        rng=out_system_h2_cost!a3          rdim=3 cdim=1
par=out_system_syn_cost       rng=out_system_syn_cost!a3         rdim=3 cdim=1
out_h2prod,out_synfuels,out_tra,,out_dhprod,out_pprod,out_nimp,out_elprod,out_nen,,out_reg_cost,out_ETSCO2,out_elcprodcap,out_veh_stock,out_biowaste,out_intrate_constr,in_h2prod,in_elprod,in_dhprod,out_system_elc_cost,out_system_dh_cost,out_agr,out_system_h2_cost,out_co2_intra_eu,

$offText

execute_unload "out%SCENARIO%.gdx",out_pprod,out_ind,out_com,out_com_esd,out_nres_sh,out_nres_wh,out_rsd,out_rsd_esd,out_rsd_sh,out_rsd_wh,out_tra,out_co2,out_h2elc,in_synfuels,out_share_dh,out_rsd_dh_sh,out_rsd_dh_wh,out_nres_dh_sh,out_nres_dh_wh;
* execute 'gdxxrw.exe i=out%SCENARIO%.gdx o="%SCENARIO%.xlsx" EpsOut="0" @out%SCENARIO%.txt'
execute 'gdxxrw.exe i=out%SCENARIO%.gdx o="%SCENARIO%.xlsb" EpsOut="0" @out%SCENARIO%.txt'

execute 'del cost_sectors%SCENARIO%.* out*%SCENARIO%*.txt out*%SCENARIO%*.gdx *%SCENARIO%*.~gm dim*%SCENARIO%*.gms'

execute_unload "%SCENARIO%.gdx"
