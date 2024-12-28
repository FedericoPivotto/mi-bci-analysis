%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Load and process each GDF file separately for both calibration and evaluation files, and save the result.

% Dataset
dataset = 'micontinuous';
dirpath_dataset = ['../dataset/', dataset, '/'];
fileext = '.gdf';

% Subjects
subject = {
    'ai6_micontinuous', ...
    'ai7_micontinuous', ...
    'ai8_micontinuous', ...
    'aj1_micontinuous', ...
    'aj3_micontinuous', ...
    'aj4_micontinuous', ...
    'aj7_micontinuous', ...
    'aj9_micontinuous' ...
};

% Scan each subject
for i = 1:size(subject, 2)
    dirpath_subject = cell2mat(strcat(dirpath_dataset, subject(i), '/'));
    files = dir(fullfile(dirpath_subject, ['*', fileext]));
    
    % Process each GDF file
    filename = strrep({files.name}, fileext, '');
    for j = 1:size(filename, 2)
        dirpath_psd = strcat('psd/', dataset, '/', subject(i), '/');
        save_psd(dirpath_subject, char(filename(j)), fileext, char(dirpath_psd));
    end
end