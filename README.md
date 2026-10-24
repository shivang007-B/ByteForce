# CL-03 — Predicting Energy Consumption for a Building

**MathWorks Climate Tech Hackathon**

---

## Problem Statement

Build an AI model that predicts a building's energy consumption from its characteristics, local weather, and other information. Use the predictions to identify buildings that are likely **wasting energy** and are strong candidates for **retrofitting**.

---

## Project Structure

| File | Purpose |
|---|---|
| `EnergyConsumptionApp.m` | ⚡ **Outstanding Cyber-Themed Frontend App** (All maps, scrollable explorer, simulator, controls) |
| `RunApp.m` | 🚀 **One-Click App Launcher** — run `RunApp` in MATLAB to start UI |
| `EnergyConsumptionPipeline.m` | **Pipeline script** — backend headless execution |
| `BuildingRegressionModels.m` | Core ML function: trains models, evaluates performance, scores retrofit candidates |
| `HelperDataPreprocessing.m` | Data cleaning, imputation, outlier removal |
| `HelperAnalyzeResults.m` | Prints performance tables, overfitting checks, feature importance |
| `HelperVisualize.m` | Generates 8 figures covering performance, residuals, uncertainty, and retrofit maps |
| `HelperRetrofitAnalysis.m` | Ranks buildings by excess energy use, estimates potential savings |
| `exampleTrain.csv` | Sample dataset (WiDS 2022 / ASHRAE) |

---

## Quick Start (Frontend App & Pipeline)

### Option A: Launch Interactive Frontend App (Recommended)
In the MATLAB Command Window, simply run:
```matlab
RunApp
% or
EnergyConsumptionApp
```
This opens the full **ByteForce Cyber AI Command Center** featuring:
- **Black Cyber + Oxford Blue + Vista Blue + Cyber Green** high-contrast UI
- **Scrollable Map Explorer** with all 5 energy & retrofit maps visible
- **AI Model Benchmarks & Leaderboard**
- **Deep Model Diagnostics & Explainability**
- **Interactive Retrofit Candidates Directory** with search & filters
- **What-If Retrofit Simulator** for live carbon & cost abatement calculations
- **Live Pipeline Controls & Real-Time Console**

### Option B: Run Headless Backend Pipeline
```matlab
EnergyConsumptionPipeline
```

### Outputs Produced
- `energy_results.mat` — trained models, validation results, retrofit scores
- `retrofit_candidates.csv` — ranked table of buildings to retrofit
- `model_predictions.csv` — actual vs predicted for all models
- Interactive frontend dashboards and exported PNG maps

---

## Dataset

The sample data is from the **WiDS Datathon 2022** (based on the ASHRAE Great Energy Predictor III challenge). It contains 75,757 buildings with 63 anonymised features and a site Energy Use Intensity (EUI) target.

For the full challenge, also consider:
- [Building Data Genome Project 2](https://github.com/buds-lab/building-data-genome-project-2)
- [ASHRAE Great Energy Predictor III (Kaggle)](https://www.kaggle.com/c/ashrae-energy-prediction)

---

## Models Trained

| Model | Key Strengths |
|---|---|
| Linear Regression | Baseline; interpretable coefficients |
| Decision Tree (pruned) | Handles non-linearity; visually explainable |
| **Random Forest** | Best generalisation; provides 95% prediction intervals |
| **Gradient Boosting** | Highest accuracy; best feature importance scores |
| SVR *(optional)* | Enable via `mdlOpts.RunSVR = true` |

---

## Key Design Decisions

### Generalisation to Unseen Buildings
When a `BuildingID` column is present, the train/test split and cross-validation folds are made at the **building level** — no building appears in both sets. This directly addresses the core challenge requirement.

### Uncertainty Quantification
For **Random Forest**, the standard deviation across individual tree predictions is used as a proxy for uncertainty, producing 95% prediction intervals. Coverage (fraction of actuals inside the interval) is reported.

### Explaining Drivers
Feature importances are extracted from the best tree ensemble (Gradient Boosting preferred, Random Forest fallback) and visualised as a ranked bar chart.

### Identifying Energy Waste
Each test building receives an **excess consumption score**:
```
excess = actual EUI − predicted EUI
```
Buildings with high excess are consuming more than expected given their size, age, and weather. These are ranked and classified as *Low / Medium / High / Critical* retrofit candidates.

---

## Configuration

Edit the options block at the top of `EnergyConsumptionPipeline.m`:

```matlab
mdlOpts.TestFraction = 0.20;   % fraction held out for test
mdlOpts.CVFolds      = 5;      % cross-validation folds
mdlOpts.NTreesRF     = 100;    % Random Forest size
mdlOpts.NTreesGB     = 100;    % Gradient Boosting rounds
mdlOpts.LearnRateGB  = 0.05;   % GBM learning rate
mdlOpts.RunSVR       = false;  % set true to include SVR
```

---

## Requirements

- MATLAB R2020b or later
- Statistics and Machine Learning Toolbox

---

## Output Files

| File | Contents |
|---|---|
| `energy_results.mat` | `trainedModels`, `results`, `retrofitTable` structs |
| `retrofit_candidates.csv` | Ranked buildings with excess EUI, severity, potential savings |
| `model_predictions.csv` | Actual EUI vs per-model predictions for test set |
