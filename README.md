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
1. Create `dataset/` folder and insert the dataset.
2. Create `toolbox/` folder and insert `biosig` and `eeglab` toolboxes.

# TODO
- `generation.m`
- `compute_topoplot.m`
- `compute_spectrogram.m`
- `compute_featuremap.m`
- `analysis.m`
- `train_model.m`
- `training.m`
- `evaluate_model.m`
- `evaluation.m`

# Questions
- Grand average on the concatenation of the concatenetions? Maybe only offline recordings.

# Authors
- Federico Pivotto, 2121720, federico.pivotto@studenti.unipd.it
- Alessandro Bozzon, 2122185, alessandro.bozzon@studenti.unipd.it
- Riccardo Simion, 2157564, riccardo.simion@studenti.unipd.it
- Riccardo Zerbinati, 2158676, riccardo.zerbinati@studenti.unipd.it
