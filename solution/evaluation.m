%% Workspace setup
clc; close all; clear;

%% Objective
% Implement a classification and control framework using MATLAB to process data, compute Fisher scores, train a model, and evaluate performance using evidence accumulation.

%% 3. Test the Model
% Write a MATLAB script to test the model on the evaluation data.

% a. Load each online file that you have processed (.mat)
psd_mat{1} = load('psd_data/ah7.20170613.170929.online.mi.mi_bhbf.ema.mat');
psd_mat{2} = load('psd_data/ah7.20170613.171649.online.mi.mi_bhbf.dynamic.mat');
psd_mat{3} = load('psd_data/ah7.20170613.172356.online.mi.mi_bhbf.dynamic.mat');
psd_mat{4} = load('psd_data/ah7.20170613.173100.online.mi.mi_bhbf.ema.mat');

% b. Concatenate the files
psd_cat = psd_mat{1};
psd_cat.PSD = cat(1, psd_mat{1}.PSD, psd_mat{2}.PSD, psd_mat{3}.PSD, psd_mat{4}.PSD); % [windows x frequencies x channels]

% c. Extract and concatenate the events
psd_cat.EVENT.POS = [ ...
    psd_mat{1}.EVENT.POS; ...
    psd_mat{2}.EVENT.POS + size(psd_mat{1}.PSD, 1); ...
    psd_mat{3}.EVENT.POS + size(psd_mat{1}.PSD, 1) + size(psd_mat{2}.PSD, 1); ...
    psd_mat{4}.EVENT.POS + size(psd_mat{1}.PSD, 1) + size(psd_mat{2}.PSD, 1) + size(psd_mat{3}.PSD, 1)];
psd_cat.EVENT.TYP = [psd_mat{1}.EVENT.TYP; psd_mat{2}.EVENT.TYP; psd_mat{3}.EVENT.TYP; psd_mat{4}.EVENT.TYP];
psd_cat.EVENT.DUR = [psd_mat{1}.EVENT.DUR; psd_mat{2}.EVENT.DUR; psd_mat{3}.EVENT.DUR; psd_mat{4}.EVENT.DUR];

% d. Use the label vectors to extract only the windows from the Cue (TYP=771 or TYP=773) to the end of Continuous feedback (TYP=781). For instance:
[psd_cat.LABEL.Tk, psd_cat.LABEL.Ck, psd_cat.LABEL.CFbK, psd_cat.LABEL.Pk, psd_cat.LABEL.Mk] = get_label_vectors(psd_cat.PSD, psd_cat.EVENT, 'online');

% i. Use predict() to evaluate the model with online data (i.e., training accuracy)
n_windows = size(psd_cat.PSD, 1);
n_frequencies = size(psd_cat.PSD, 2);
n_channels = size(psd_cat.PSD, 3);
n_features = n_frequencies * n_channels;

psd_cat.PSD_feature = reshape(psd_cat.PSD, n_windows, n_features); % [windows x features]

model_mi_bhbf = load('model/model.mi_bhbf.mat');
LabelIdx = psd_cat.LABEL.CFbK == 781 & psd_cat.LABEL.Mk == 1; % Online data during continuous feedback + CHECK: Class 0 removal
[Gk, pp] = predict(model_mi_bhbf.Model, psd_cat.PSD_feature(LabelIdx, model_mi_bhbf.FeaturesIdx));

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
bar_accuracies = [overall_accuracy; class_accuracies(1); class_accuracies(2)];
bar(bar_classes, bar_accuracies);
set(gca, ...
    'Title', text('String', 'Single sample accuracy on testset'), ...
    'YLabel', text('String', 'Accuracy [%]'), ...
    'YLim', [0, 100], ...
    'YGrid', 'on');

%% 4. Exponential Smoothing
% Apply exponential smoothing to the raw probabilities from the evaluation data using the following formula:
% 𝐷(𝑡) = α · 𝑝𝑝(𝑡) + (1 − α) · 𝐷(𝑡 − 1)
% Where:
% - pp(t) is the posterior probability at window t
% - D(t−1) is the output of the control framework at time t−1
% - α is the integration parameter

% Notes:
% - The output D(t) must reset to 0.5 at the beginning of each trial (i.e., when EVENT.TYP == 781).
% - When D(t) reaches a fixed threshold (e.g., [0.2, 0.8]), a decision is made for that trial.
% - Thresholds for class 1 and class 2 can differ but must be predetermined.

alpha = 0.97; % Integration parameter: Tip: 0.96-0.98
threshold.both_feet = 0.8; % Decision threshold for both feet
threshold.both_hands = 0.2; % Decision threshold for both hands

n_step = size(pp, 1);

Tk_trials = psd_cat.LABEL.Tk(psd_cat.LABEL.Tk ~= 0);
n_trials = size(unique(Tk_trials), 1);
decisions = zeros(n_trials, 1); % Decisions vector

D = 0.5; % Initial value for D(t)
trial_id = 0; % Trial number from 1
i = 1;

for t = 1 : n_step
    % Reset D(t) at trial start
    if psd_cat.LABEL.CFbK(i) == 0
        while psd_cat.LABEL.CFbK(i) == 0
            i = i + 1;
        end
        
        D = 0.5;
        trial_id = trial_id + 1;
    end

    % Exponential smoothing
    D = alpha * pp(t, 1) + (1 - alpha) * D;
    
    % Make a decision if threshold reached
    if D > threshold.both_feet
        decisions(trial_id) = 771; % Both feet decision
    elseif D < threshold.both_hands
        decisions(trial_id) = 773; % Both hands decision

    i = i + 1;
end

% Plot decisions over time
figure;
plot(1:n_trials, decisions);
set(gca, ...
    'Title', text('String', 'Exponential smoothed decisions'), ...
    'YLabel', text('String', 'Trial'), ...
    'YGrid', 'on');