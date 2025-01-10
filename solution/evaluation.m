%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

% function evaluate_model(path_model, dirpath_in, filename, fileext, dirpath_out)
% INFO: path_model: 'solution/model/micontinuous/<subject>/<filename_with_ext>', 'solution/model/micontinuous/population/<filename_with_ext>'
% INFO: dirpath_in: 'solution/psd/micontinuous/<subject>/', 'solution/psd/micontinuous/population/'
% INFO: filename: '<filename_without_ext>'
% INFO: fileext: '.mat'
% INFO: dirpath_out: 'solution/model/micontinuous/<subject>/', 'solution/model/micontinuous/population/'

%% Evaluate subjects and population trained classification models

% Trained models
dataset = 'micontinuous';
dirpath_model = ['model/', dataset, '/'];
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

    % Directory in which read the trained model
    dirpath_model_subject = strcat(dirpath_model, subject(i), '/');
    % Consider trained model on offline recordings
    path_model = strcat(dirpath_model_subject, 'model.', subject_id, '.offline.mi.mi_bhbf', fileext.mat);
    
    % Directory in which read the PSD
    dirpath_psd_subject = strcat(dirpath_psd, subject(i), '/');

    % Get MAT files in subject directory
    dirpath_subject = cell2mat(dirpath_psd_subject);
    files = dir(fullfile(dirpath_subject, ['*', fileext.mat]));
    filename = strrep({files.name}, fileext.mat, '');

    % Train and save model in MAT file
    for j = 1:size(filename, 2)
        % Consider online recordings
        if ~contains(filename(j), strcat(subject_id, '.online'))
            continue;
        end
        evaluate_model(path_model, dirpath_subject, filename(j), fileext.mat, dirpath_model_subject);
    end
end