%% Workspace setup
clc; close all; clear;

%% TODO: adapt this script (LAB7) to our structure and to train a model for each subject and the whole population.

%% Objective
% Implement a classification and control framework using MATLAB to process data, compute Fisher scores, train a model, and evaluate performance using evidence accumulation.

%% 2. Compute Fisher Score and Train Model
%  - Develop a script to compute the Fisher score and train a model on the calibration data
%  - Save the trained model in a .mat file

% a. Load each offline file that you have processed (.mat)
psd_mat{1} = load('psd_data/ah7.20170613.161402.offline.mi.mi_bhbf.mat');
psd_mat{2} = load('psd_data/ah7.20170613.162331.offline.mi.mi_bhbf.mat');
psd_mat{3} = load('psd_data/ah7.20170613.162934.offline.mi.mi_bhbf.mat');

% b. Concatenate the files
psd_cat = psd_mat{1};
psd_cat.PSD = cat(1, psd_mat{1}.PSD, psd_mat{2}.PSD, psd_mat{3}.PSD); % [windows x frequencies x channels]

% c. Extract and concatenate the events
psd_cat.EVENT.POS = [psd_mat{1}.EVENT.POS; psd_mat{2}.EVENT.POS + size(psd_mat{1}.PSD, 1); psd_mat{3}.EVENT.POS + size(psd_mat{1}.PSD, 1) + size(psd_mat{2}.PSD, 1)];
psd_cat.EVENT.TYP = [psd_mat{1}.EVENT.TYP; psd_mat{2}.EVENT.TYP; psd_mat{3}.EVENT.TYP];
psd_cat.EVENT.DUR = [psd_mat{1}.EVENT.DUR; psd_mat{2}.EVENT.DUR; psd_mat{3}.EVENT.DUR];

% d. Use the label vectors to extract only the windows from the Cue (TYP=771 or TYP=773) to the end of Continuous feedback (TYP=781). For instance:
[psd_mat{1}.LABEL.Tk, psd_mat{1}.LABEL.Ck, psd_mat{1}.LABEL.CFbK, psd_mat{1}.LABEL.Pk, psd_mat{1}.LABEL.Mk] = get_label_vectors(psd_mat{1}.PSD, psd_mat{1}.EVENT, 'offline');
[psd_mat{2}.LABEL.Tk, psd_mat{2}.LABEL.Ck, psd_mat{2}.LABEL.CFbK, psd_mat{2}.LABEL.Pk, psd_mat{2}.LABEL.Mk] = get_label_vectors(psd_mat{2}.PSD, psd_mat{2}.EVENT, 'offline');
[psd_mat{3}.LABEL.Tk, psd_mat{3}.LABEL.Ck, psd_mat{3}.LABEL.CFbK, psd_mat{3}.LABEL.Pk, psd_mat{3}.LABEL.Mk] = get_label_vectors(psd_mat{3}.PSD, psd_mat{3}.EVENT, 'offline');
[psd_cat.LABEL.Tk, psd_cat.LABEL.Ck, psd_cat.LABEL.CFbK, psd_cat.LABEL.Pk, psd_cat.LABEL.Mk] = get_label_vectors(psd_cat.PSD, psd_cat.EVENT, 'offline');

% e. For each feature (channel-frequency pair), compute the Fisher Score.
% Suggestion: it is better to first reshape the data in the format [windows x features]
% (be careful to be able to convert back features index to channel/frequency)
psd_mat{1}.fisher_scores_matrix = get_fisher_score_matrix(psd_mat{1}.PSD, psd_mat{1}.LABEL.Pk);
psd_mat{2}.fisher_scores_matrix = get_fisher_score_matrix(psd_mat{2}.PSD, psd_mat{2}.LABEL.Pk);
psd_mat{3}.fisher_scores_matrix = get_fisher_score_matrix(psd_mat{3}.PSD, psd_mat{3}.LABEL.Pk);
psd_cat.fisher_scores_matrix = get_fisher_score_matrix(psd_cat.PSD, psd_cat.LABEL.Pk);

% f. Visualize the features maps (one for each offline file) by using imagesc()
figure; % Create plot window
m = 1; n = 4; % Subplots window size
sgtitle('Features maps for the calibration runs (Fisher score)');

n_channels = size(psd_cat.PSD, 3);
channel_labels = {'Fz', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'C3', 'C1', 'Cz', 'C2', 'C4', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4'};
channels = dictionary(channel_labels, 1:n_channels);
clim = [0 1];

for i = 1:3
    subplot(m, n, i);
    imagesc(psd_mat{1}.FREQ_subset, 1:n_channels, flip(rot90(psd_mat{i}.fisher_scores_matrix(psd_mat{i}.FREQ_index, :), 1), 1), clim);
    set(gca, ...
        'Subtitle', text('String', ['Calibrarion run ', num2str(i)]), ...
        'XLabel', text('String', 'Frequency [Hz]'), ...
        'YLabel', text('String', 'Channel'), ...
        'XTickLabelRotation', 90, ...
        'XTick', psd_mat{i}.FREQ_subset, ...
        'YTickLabel', keys(channels), ...
        'YTick', values(channels));
    colorbar;
end

subplot(m, n, 4);
imagesc(psd_cat.FREQ_subset, 1:n_channels, flip(rot90(psd_cat.fisher_scores_matrix(psd_cat.FREQ_index, :), 1), 1), clim);
set(gca, ...
    'Subtitle', text('String', 'Calibrarion run ALL'), ...
    'XLabel', text('String', 'Frequency [Hz]'), ...
    'YLabel', text('String', 'Channel'), ...
    'XTickLabelRotation', 90, ...
    'XTick', psd_cat.FREQ_subset, ...
    'YTickLabel', keys(channels), ...
    'YTick', values(channels));
colorbar;

% g. Select the most discriminative features and extract them in a new matrix
n_windows = size(psd_cat.PSD, 1);
n_frequencies = size(psd_cat.PSD, 2);
n_channels = size(psd_cat.PSD, 3);
n_features = n_frequencies * n_channels;

frequencies = dictionary(psd_cat.FREQ_subset, psd_cat.FREQ_index);

% Cz: 22 Hz, 24 Hz, C1: 12 Hz
selected_features = [frequencies(22), channels({'Cz'}); frequencies(24), channels({'Cz'}); frequencies(12), channels({'C1'})]; % Pairs frequency-channel
FeaturesIdx = sub2ind([n_frequencies, n_channels], selected_features(:, 1), selected_features(:, 2)); % Linear indices for the 3D matrix

% h. Use fitcdiscr() to train a model only with the data
psd_cat.PSD_feature = reshape(psd_cat.PSD, n_windows, n_features); % [windows x features]
LabelIdx = psd_cat.LABEL.CFbK == 781 & psd_cat.LABEL.Mk == 0; % Offline data during continuous feedback

Model = fitcdiscr(psd_cat.PSD_feature(LabelIdx, FeaturesIdx), psd_cat.LABEL.Pk(LabelIdx), 'DiscrimType','quadratic');

% i. Use predict() to evaluate the model with offline data (i.e., training accuracy)
[Gk, pp] = predict(Model, psd_cat.PSD_feature(LabelIdx, FeaturesIdx));

% The accuracy must be computed for both classes together (i.e., overall accuracy) and for each class separately. Accuracies must be reported as bar plots
true_labels = psd_cat.LABEL.Pk(LabelIdx); % Ground truth labels
predictions = Gk;

% Compute overall accuracy
overall_accuracy = mean(predictions == true_labels) * 100;

classes = unique(true_labels); % Unique class labels
class_accuracies = zeros(length(classes), 1); % Class-wise accuracy

for i = 1:length(classes)
    class_accuracies(i) = mean(Gk(true_labels == classes(i)) == classes(i)) * 100;
end

disp(['Overall accuracy: ', num2str(overall_accuracy), '%']); % Display accuracies
for i = 1:length(classes)
    disp(['Accuracy for class ', num2str(classes(i)), ': ', num2str(class_accuracies(i)), '%']);
end

figure; % Bar plot for accuracies
bar_classes = ["Overall", "771 - Both feet", "773 - Both hands"];
bar_accuracies = [overall_accuracy; class_accuracies(1) ; class_accuracies(2)];
bar(bar_classes, bar_accuracies);
set(gca, ...
    'Title', text('String', 'Single sample accuracy on trainset'), ...
    'YLabel', text('String', 'Accuracy [%]'), ...
    'YLim', [0, 100], ...
    'YGrid', 'on');

% j. Save the trained model in a .mat file
save(['model/', 'model.mi_bhbf', '.mat'], 'Model', 'FeaturesIdx' ,'Gk', 'pp');