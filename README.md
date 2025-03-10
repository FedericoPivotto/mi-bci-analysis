# MI BCI Analysis
Analysis of data collected during a 3-day Motor Imagery (MI) Brain-Computer Interface (BCI) experiment involving 8 healthy participants.

## MATLAB Toolbox

### `biosig`
```matlab
disp('[config] - Adding biosig toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t200_FileAccess'));
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\biosig\biosig\t250_ArtifactPreProcessingQualityControl'));

% NOTE: Toolbox version may be different
```

### `eeglab`
```matlab
disp('[config] - Adding eeglab toolbox');
addpath(genpath('<absolute-path>\mi-bci-analysis\toolbox\eeglab\eeglab2024.2'));

% NOTE: Toolbox version may be different
```

## Dataset
The data was recorded using a 16-channel EEG amplifier at a sampling rate of 512 Hz, where the electrodes were positioned according to the 10-20 international system.

Each participant completed at least two recording days:

- Day 1: 3 "offline" runs (calibration, without real feedback) and 2 "online" runs
(with real feedback);
- Day 2 and Day 3: 2 "online" runs per day.

### Resource
https://cloud.dei.unipd.it/index.php/s/DLJfJccgFnFiDZY

## Instructions
1. Create `toolbox/` folder in root directory and insert `biosig` and `eeglab` toolboxes
2. Create `dataset/` folder in root directory and insert `micontinuous` dataset
3. Run `generation.m` script
4. Run `analysis.m` script
5. Run `selection.m` script
6. Run `training.m` script
7. Run `evaluation.m` script

### Tested Environments
- Local machine, Windows 11, MATLAB R2024b
- Local machine, MacOS Sequoia, MATLAB R2024b
- Local machine, Windows 11, MATLAB R2023a
- Local machine, Windows 11, MATLAB R2023b

## Authors
- Federico Pivotto, 2121720, federico.pivotto@studenti.unipd.it
- Alessandro Bozzon, 2122185, alessandro.bozzon@studenti.unipd.it
- Riccardo Simion, 2157564, riccardo.simion@studenti.unipd.it
- Riccardo Zerbinati, 2158676, riccardo.zerbinati@studenti.unipd.it

### Contributions
| Member             | Workload | Work                                                                                                                                                                |
| ------------------ | :------: |-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Federico Pivotto   | 25%      | Project structure, data generation, training workflow, evaluation workflow, feature selection, selection workflow, model training and evalutation chapter in report |
| Alessandro Bozzon  | 25%      | Topoplot computation, analysis workflow, feature selection, performance metrics, topoplot chapter in report                                                         |
| Riccardo Simion    | 25%      | Spectrogram computation, model training, feature selection, spectrogram chapter in report                                                                           |
| Riccardo Zerbinati | 25%      | Feature map computation, model evaluation, feature selection, feature map chapter in report                                                                         |
