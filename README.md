# Minimum requirements to solve the model

Before running the model, ensure that your system satisfies the following requirements:

- A valid **GAMS/CPLEX** license
- At least **64 GB RAM**
- More than **10 CPU threads**
- At least **10 GB** of available disk space
- Basic knowledge of the **TIMES modelling framework** (see also: https://iea-etsap.org/index.php/documentation)

---

# Installation

Download both directories into the same parent folder on your local computer.

The directory structure should be:

```text
Project/
├── Gams_WrkJRCTIMES/
└── Results/
```

- **`Gams_WrkJRCTIMES/`** contains the model input data.
- **`Results/`** contains the model result generation routines and template files.

---

# Contents of the model input data directory

The model code and input data are stored as plain text files with the `.dmp` extension.

The directory also contains:

- Solver option files
- Scripts to execute the POLIZERO scenarios
- Post-solution files containing the raw results generated for each scenario

The contents of this directory are described below.

---

## Model input data files

| File | Description |
|------|-------------|
| `CLI_MM.dmp` | JRC-EU-TIMES input data and model code for the **CLI_MM** scenario used to provide electricity system boundary conditions to **highRES**. |

---

## Other files required for solving the model

Besides the model input and source code, the following files control the execution of the model.

| File | Description |
|------|-------------|
| `cplex.opt` | CPLEX solver option file |
| `vtrun.CMD` | Script used to execute the `CLI_MM` scenario |

---

## Post-solution files

After the JRC-EU-TIMES model successfully finishes, the corresponding **GDX** file is automatically generated in the `GAMSSAVE` subdirectory.

The folder currently contains:

| File | Description |
|------|-------------|
| `CLI_MM.gdx` | GDX output generated for the `CLI_MM` scenario |

The GDX files are subsequently translated into flat text files with the extensions:

- `.vd`
- `.vde`
- `.vds`

These files store the model results in a format compatible with the **VEDA** user interface for TIMES models.

For additional information on VEDA, see:

https://iea-etsap.org/index.php/documentation

---

# Contents of the model results directory

The `Results` directory contains the routines required to process the TIMES outputs and generate the final Excel reports.

## Processing routines

| File | Description |
|------|-------------|
| `collect_results_single_scenario_WIMBY.gms` | GAMS routine that converts the TIMES `.vd` files into a format suitable for Excel processing. |

## Result templates

| File | Description |
|------|-------------|
| `results_template_WIMBY.xlsb` | Excel template containing the boundary conditions and output structure used for the HighRES project. |

## Scenario results

| File | Description |
|------|-------------|
| `CLI_MM.xlsb` | Excel results generated for the `CLI_MM` scenario. |

## Execution scripts

| File | Description |
|------|-------------|
| `collect_wimby.bat` | Main batch script used to generate the Excel output files from a completed TIMES model run. |

---

# Example workflow

The typical workflow is as follows:

1. Execute the script

   ```text
   CLI_MM.CMD
   ```

   to solve the `CLI_MM` scenario.

2. After the model finishes successfully, execute

   ```text
   collect_wimby.bat
   ```

   to generate the corresponding Excel results file.
