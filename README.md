# MI BCI Analysis
Analysis of data collected during a 3-day Motor Imagery (MI) Brain-Computer Interface (BCI) experiment involving 8 healthy participants.

## TODO

### Analysis
- [x] `generation.m`
- [x] `compute_topoplot.m`
- [x] `compute_spectrogram.m`
- [x] `compute_featuremap.m`
- [ ] `analysis.m` (fix spectrogram and feature map in MacOS and Linux)

### Classification
- [x] `selection.m`
- [ ] `train_model.m` (check bar-plot order)
- [x] `training.m`
- [ ] `evaluate_model.m` (add time and other metrics, check bar-plot order)
- [x] `evaluation.m`

### Deadline
??/01/2025

### Report
https://www.overleaf.com/9146575821jhxjqvbrdynv#3b2c30

## MATLAB Toolbox

### `biosig`
```matlab
disp('[config] - Adding biosig toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t200_FileAccess'));
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t250_ArtifactPreProcessingQualityControl'));
```

### `eeglab`
```matlab
disp('[config] - Adding eeglab toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\eeglab\eeglab2024.2'));
```

## Dataset
The data was recorded using a 16-channel EEG amplifier at a sampling rate of 512 Hz, where the electrodes were positioned according to the 10-20 international system.

Each participant completed at least two recording days:

- Day 1: 3 "offline" runs (calibration, without real feedback) and 2 "online" runs
(with real feedback).
- Day 2 and Day 3: 2 "online" runs per day.

### Resource
https://cloud.dei.unipd.it/index.php/s/DLJfJccgFnFiDZY

## Instructions
1. Create `dataset/` folder and insert `micontinuous` dataset.
2. Create `toolbox/` folder and insert `biosig` and `eeglab` toolboxes.
3. Run `generation.m` script.
4. Run `analysis.m` script.
5. Run `selection.m` script.
6. Run `training.m` script.
7. Run `evaluation.m` script.

## Authors
- Federico Pivotto, 2121720, federico.pivotto@studenti.unipd.it
- Alessandro Bozzon, 2122185, alessandro.bozzon@studenti.unipd.it
- Riccardo Simion, 2157564, riccardo.simion@studenti.unipd.it
- Riccardo Zerbinati, 2158676, riccardo.zerbinati@studenti.unipd.it

### Contribution
| Member             | Work                                                                                           |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| Federico Pivotto   | Data generation, training workflow, evaluation workflow, feature selection, selection workflow |
| Alessandro Bozzon  | Topoplot computation, analysis workflow, feature selection                                     |
| Riccardo Simion    | Spectrogram computation, model training, feature selection                                     |
| Riccardo Zerbinati | Feature map computation, model evaluation, feature selection                                   |
