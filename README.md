# WTLib (Wind Turbine Library)

A MATLAB-based library for parametric wind turbine blade design and analysis using NuMAD as a backend. WTLib leverages object-oriented programming to "puppeteer" NuMAD workflows, enabling automated generation, modification, and evaluation of blade designs for research and design space exploration.

---

## Overview

WTLib provides a high-level interface to:

* Define wind turbine blade geometries programmatically
* Interface with NuMAD without relying on Excel-only workflows
* Perform automated analyses (beam models, operating points, etc.)
* Conduct design space exploration (DSE)
* Match blade designs based on:

  * Axial induction distributions (Jamieson model)
  * Root bending moments
  * Tip deflection

The library is particularly suited for multidisciplinary design optimization (MDO) studies and reproducible research workflows.

---

## Key Features

### 1. Object-Oriented Blade Definition

* Central class: `bladeParam`
* Encapsulates:

  * Geometry
  * Materials
  * Components
  * Operating conditions

### 2. NuMAD Integration

* Automates:

  * Blade updates
  * Beam model generation
  * Structural analysis
* Avoids manual GUI interaction

### 3. Flexible Input System

* Inputs are not restricted to Excel
* Custom parsing supported (e.g., `.xlsx`, future support for standardized formats like `wind.io`)

### 4. Design Space Exploration

* Grid-based exploration of aerodynamic parameters
* Parallel execution support via MATLAB `parpool` and `parfeval`

### 5. Matching Algorithms

* **Jamieson Fit**: Fits axial induction curves
* **Moment Matching**: Matches root bending moments
* **Tip Deflection Matching**: Matches structural compliance

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/jjmoraa/WTLib.git
```

### 2. Set Up Paths in MATLAB

Ensure all required toolboxes and dependencies are available.

Run:

```matlab
addWindTurbinesLib()
```

Modify this function to correctly point to:

* NuMAD source
* External tools (e.g., BModes, PreComp, ANSYS if used)

---

## Dependencies

WTLib relies on a modified version of NuMAD maintained alongside this repository.

### Required

* MATLAB (Parallel Computing Toolbox recommended)
* **Custom NuMAD fork** (required): [https://github.com/jjmoraa/NuMAD-3.00_devUMass](https://github.com/jjmoraa/NuMAD-3.00_devUMass)

### Optional

* BModes
* PreComp
* ANSYS

---

## Installation

### 1. Clone WTLib

```bash
git clone https://github.com/jjmoraa/WTLib.git
```

### 2. Clone the Modified NuMAD (Required)

WTLib depends on a custom NuMAD version. Clone it as a **sibling directory** (same parent folder as WTLib):

```bash
git clone https://github.com/jjmoraa/NuMAD-3.00_devUMass.git
```

### 3. Directory Structure (Important)

Your folder structure should look like:

```
parent_directory/
├── WTLib/
└── NuMAD-3.00_devUMass/
```

### 4. Set Up Paths in MATLAB

Run:

```matlab
addWindTurbinesLib()
```

Modify this function if needed so it correctly points to:

* WTLib
* The modified NuMAD directory
* External tools (BModes, PreComp, ANSYS, etc.)

---

## Typical Workflow

Below is a simplified outline of a typical WTLib workflow.

### 1. Initialize Environment

```matlab
addWindTurbinesLib();
[inputs, airfoils] = scriptInit_v2(dataFolder);
```

### 2. Create Reference Blade

```matlab
[geometryVec, materialsVec, componentsVec] = parseInputs(inputs, inputFile);

refBlade = bladeParam(...);
refBlade.updateBlade;
refBlade.generateBeamModel;
refBlade.operatingPoint;
```

### 3. Fit Aerodynamic Model

```matlab
[fitcurve, gof] = jamiesonsFitv2(refBlade, rootPct);
```

### 4. Generate Matching Designs

* Moment-matching blade
* Tip-deflection-matching blade

### 5. Design Space Exploration

```matlab
grid_points = JamiesonsBoundGenerator(...);

for idx = 1:length(grid_points)
    % Generate blade
    % Run analysis
end
```

Parallel execution supported via:

```matlab
parfeval
```

---

## Folder Structure

```
WTLib/
├── source/                # Core library code
├── examples/              # Example scripts
├── data/                  # Input data
├── results/               # Output results
├── utilities/             # Helper functions
└── README.md
```

---

## Naming Convention

Generated blades are automatically labeled using:

```
mommat_idxXXX_nX.XXX_pX.XXX
```

or

```
dflmat_idxXXX_nX.XXX_pX.XXX
```

This ensures traceability across large parametric studies.

---

## Parallelization

WTLib supports parallel execution using MATLAB's parallel toolbox:

```matlab
if isempty(gcp('nocreate'))
    parpool(N)
end
```

Asynchronous execution example:

```matlab
f = parfeval(@functionName, 1, args...);
wait(f, 'finished', timeout);
result = fetchOutputs(f);
```

---

## Example Use Case

The library has been used to:

* Analyze the IEA 15MW reference turbine
* Generate families of blades with equivalent:

  * Aerodynamic performance
  * Structural response
* Perform trade studies between stiffness and loading

---

## Future Work

* Integration with standardized input formats (e.g., wind.io)
* GUI or lightweight app interface
* Docker/containerized deployment
* Expanded optimization frameworks

---

## Author

Jose Mora
University of Massachusetts Amherst

---

## License

Specify your license here (e.g., MIT License, BSD, etc.)

---

## Acknowledgments

* NuMAD development team
* Wind energy research community

---

## Contact

For questions or collaboration inquiries, please open an issue on GitHub or contact the author.

