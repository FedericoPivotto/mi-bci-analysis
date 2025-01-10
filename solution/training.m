%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Train subjects and population classification models

% PSD data
dataset = 'micontinuous';
dirpath_psd = ['psd/', dataset, '/'];
fileext = struct('gdf', '.gdf', 'mat', '.mat');

% Subjects
subject = {
    'ai6_micontinuous', ...
    'ai7_micontinuous', ...
    'ai8_micontinuous', ...
    'aj1_micontinuous', ...
    'aj3_micontinuous', ...
    'aj4_micontinuous', ...
    'aj7_micontinuous', ...
    'aj9_micontinuous', ...
    'population'
};

% Scan each subject
for i = 1:size(subject, 2)
    % Get subject ID
    subject_id = strrep(subject(i), strcat('_', dataset), '');

    % Directory in which read the PSD
    dirpath_psd_subject = strcat(dirpath_psd, subject(i), '/');
    % Directory in which save the model
    dirpath_model = strcat('model/', dataset, '/', subject(i), '/');

    % Get MAT files in subject directory
    dirpath_subject = cell2mat(dirpath_psd_subject);
    files = dir(fullfile(dirpath_subject, ['*', fileext.mat]));
    filename = strrep({files.name}, fileext.mat, '');

    % Train and save model in MAT file
    for j = 1:size(filename, 2)
        % Consider offline recordings
        if ~contains(filename(j), strcat(subject_id, '.offline'))
            continue;
        end
        train_model(dirpath_subject, filename(j), fileext.mat, dirpath_model);
    end
end