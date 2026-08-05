Minimum requirements to solve the model

A valid GAMS/CPLEX License 64 GB RAM CPU threads >10 HDD space 10 GB Basic Knowledge of the TIMES modelling Framework (see also https://iea-etsap.org/index.php/documentation) Installation

Download all two directories into the same folder at a local computer. The structure the three directories is as follows:

Gams_WrkJRCTIMES : contains the model input data 
Results : contains the model result generation routines and template files Contents of the model input data directory

The model code and input data are in flat text files with the extension .dmp . The folder also contains additional files like solver options and the scripts to run the POLIZERO scenarios. In addition, the post-model solution files, with the results of each scenario in raw output format, are also located in this folder. All the above are explained in the subsections below


Model input data files:CLI_MM.dmp JRC-EU-TIMES input data and code for the medium-medium scenario of HighRES in terms capacity potential for onshore and offshore wind capacity potential.

Other files required for solving the model
Besides the data input and model code files, there are also additional files controlling the solution of the model.

cplex.opt : CPLEX solver option files
vtrun.CMD : script to run the CLI_MM scenario 

Post-solution files
When the solution of a scenario with the JRC-EU-TIMES finishes, the corresponding GDX file is generated at the subfolder GAMSSAVE. There are three GDX files alreaydy there:

CLI_MM.gdx : CLI_MM scenario GDX file

These GDX files are translated into flat text files with extensions .vds, .vde and .vd. These files contain the output of the model in a format suitable for the TIMES licensed user interface VEDA (please see https://iea-etsap.org/index.php/documentation)

Contents of the model results directory
The subfolder Results contain the following files:

collect_results_single_scenario_WIMBY.gms : is a routine to process the .vd files of TIMES to a format suitable for EXCEL
results_template_WIMBY.xlsb : results template file in EXCEL format for the boundary conditions for HighRES
CLI_MM.xlsb : results from the CLI_MM scenario of in EXCEL
The subfolder also contains the scripts to produce the results from a TIMES run:

collect_wimby.bat : batch main script to generate the EXCEL files with the results from CLI_MM

Example of the workflow with the JRC-EU-TIMES
execute the scripts CLI_MM.CMD to run the CLI_MM scenario
execute the script collect_wimby.bat to create the results EXCEL file
