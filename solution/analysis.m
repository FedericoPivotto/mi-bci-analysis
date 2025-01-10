%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% For all the GDF and MAT files, it uses the functions compute_topoplot, compute_spectrogram and compute_featuremap.

% TODO
% Trained models
dataset = 'micontinuous';
dirpath_psd = ['psd/', dataset, '/'];
dirpath_gdf = ['gdf/', dataset, '/'];
dirpath_results = ['result/', dataset, '/'];
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
    
    % Directory in which to read the PSD
    dirpath_psd_subject = strcat(dirpath_psd, subject(i), '/');
    % Directory in which to read the GDF
    dirpath_gdf_subject = strcat(dirpath_gdf, subject(i), '/');
    % Directory in which to save subject Topoplots 'solution/result/micontinuous/<subject>/topoplot/'
    dirpath_topoplots_subject = strcat(dirpath_results, subject(i), '/topoplot/');
    % Directory in which to save subject Spectrograms 'solution/result/micontinuous/<subject>/spectrogram/'
    dirpath_spectrograms_subject = strcat(dirpath_results, subject(i), '/spectrogram/');
    % Directory in which to save subject Feature maps 'solution/result/micontinuous/<subject>/featuremap/'
    dirpath_featuremaps_subject = strcat(dirpath_results, subject(i), '/featuremap/');

    % Get MAT files in subject directory for psd
    dirpath_subject_psd = cell2mat(dirpath_psd_subject);
    psd_files = dir(fullfile(dirpath_subject_psd, ['*', fileext.mat]));
    filename_psd = strrep({psd_files.name}, fileext.mat, '');

    % Get MAT(concatenated GDFs) files in subject directory for gdf
    dirpath_subject_gdf = cell2mat(dirpath_gdf_subject);
    gdf_files = dir(fullfile(dirpath_subject_gdf, ['*', fileext.mat]));
    filename_gdf = strrep({gdf_files.name}, fileext.mat, '');

    % Compute topoplots for retrieved gdf files
    for h = 1:size(filename_gdf,2)
        if contains(filename_gdf(1,h), 'online')
            dirpath_topoplots_subject_type = strcat(dirpath_topoplots_subject, 'online/');
        elseif contains(filename_gdf(1,h), 'offline')
            dirpath_topoplots_subject_type = strcat(dirpath_topoplots_subject, 'offline/');
        end
        compute_topoplot(dirpath_subject_gdf, filename_gdf(1,h), '.mat', dirpath_topoplots_subject_type);
    end

    % Compute spectrograms and feature maps for retrieved psd files
    for h = 1:size(filename_psd,2)
        % Consider concatenated recordings
        if (~contains(filename_psd(1,h), strcat(subject_id, '.online'))) && (~contains(filename_psd(1,h), strcat(subject_id, '.offline')))
            continue;
        end
        compute_spectrogram(dirpath_subject_psd, filename_psd(1,h), '.mat', dirpath_spectrograms_subject);
        compute_featuremap(dirpath_subject_psd, filename_psd(1,h), '.mat', dirpath_featuremaps_subject);
    end
end

% NOTE: for each feature map, qualitatively select and save the most relevant features in a unique .mat file to be saved in solution/resource/