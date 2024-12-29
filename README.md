# MI BCI Analysis
Analysis of data collected during a 3-day Motor Imagery (MI) Brain-Computer Interface (BCI) experiment involving 8 healthy participants.

# Report
OverLeaf: https://www.overleaf.com/9146575821jhxjqvbrdynv#3b2c30

# MATLAB Toolbox

## `biosig`
```matlab
disp('[config] - Adding biosig toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t200_FileAccess'));
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t250_ArtifactPreProcessingQualityControl'));
```

## `eeglab`
```matlab
disp('[config] - Adding eeglab toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\eeglab\eeglab2024.2'));
```

# Dataset
Link: https://cloud.dei.unipd.it/index.php/s/DLJfJccgFnFiDZY

# Instructions
1. Create `dataset/` folder and insert `micontinuous` dataset.
2. Create `toolbox/` folder and insert `biosig` and `eeglab` toolboxes.
3. Run `generation.m` script.
4. Run `analysis.m` script.
5. Run `training.m` script.
6. Run `evaluation.m` script.

# TODO

## Analysis
- `generation.m` (Federico)
- `compute_topoplot.m` (Alessandro)
- `compute_spectrogram.m` (Riccardo)
- `compute_featuremap.m` (Zerby)
- `analysis.m`

## Classification
- `train_model.m`
- `training.m`
- `evaluate_model.m`
- `evaluation.m`

## Deadline
05/01/2025

# Questions
- Grand average analysis on the concatenation of the concatenations? Maybe only about the offline recordings.

# Authors
- Federico Pivotto, 2121720, federico.pivotto@studenti.unipd.it
- Alessandro Bozzon, 2122185, alessandro.bozzon@studenti.unipd.it
- Riccardo Simion, 2157564, riccardo.simion@studenti.unipd.it
- Riccardo Zerbinati, 2158676, riccardo.zerbinati@studenti.unipd.it
