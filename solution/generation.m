%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Load and process each GDF file separately for both calibration and evaluation files, and save the result.

% Dataset
dataset = 'micontinuous';
dirpath_dataset = ['../dataset/', dataset, '/'];
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
    'aj9_micontinuous' ...
};

% Scan each subject
for i = 1:size(subject, 2)
    % Get subject ID
    subject_id = strrep(subject(i), strcat('_', dataset), '');

    % Get GDF files in subject directory
    dirpath_subject = cell2mat(strcat(dirpath_dataset, subject(i), '/'));
    files = dir(fullfile(dirpath_subject, ['*', fileext.gdf]));

    % Scan each GDF file
    filename = strrep({files.name}, fileext.gdf, '');
    subject_filenames{i}.offline = [];
    subject_filenames{i}.online = [];
    for j = 1:size(filename, 2)
        % Save offline/online GDF filename
        if(contains(filename(j), 'offline'))
            subject_filenames{i}.offline = [subject_filenames{i}.offline, filename(j)];
        elseif(contains(filename(j), 'online'))
            subject_filenames{i}.online = [subject_filenames{i}.online, filename(j)];
        end
    end

    % Directory in which save concatenations in MAT file
    dirpath_gdf = strcat('gdf/', dataset, '/', subject(i), '/');

    % Concatenate and save offline GDF files
    subject_filename.offline = strcat(subject_id, '.offline.mi.mi_bhbf');
    concatenate_gdf(dirpath_subject, subject_filename.offline, fileext.gdf, dirpath_gdf, subject_filenames{i}.offline);
    
    % Concatenate and save online GDF files
    subject_filename.online = strcat(subject_id, '.online.mi.mi_bhbf');
    concatenate_gdf(dirpath_subject, subject_filename.online, fileext.gdf, dirpath_gdf, subject_filenames{i}.online);
end

% Scan each subject
for i = 1:size(subject, 2)
   % Directory in which save the PSD
    dirpath_psd = strcat('psd/', dataset, '/', subject(i), '/');

    % Get GDF files in subject directory
    dirpath_subject = cell2mat(strcat(dirpath_dataset, subject(i), '/'));
    files = dir(fullfile(dirpath_subject, ['*', fileext.gdf]));
    filename = strrep({files.name}, fileext.gdf, '');
    % Process each GDF file and save PSD in MAT file
    for j = 1:size(filename, 2)
        compute_psd(dirpath_subject, filename(j), fileext.gdf, dirpath_psd);
    end

    % Get MAT files in subject directory
    dirpath_gdf = ['gdf/', dataset, '/'];
    dirpath_subject = cell2mat(strcat(dirpath_gdf, subject(i), '/'));
    files = dir(fullfile(dirpath_subject, ['*', fileext.mat]));
    filename = strrep({files.name}, fileext.mat, '');
    % Process each MAT file and save PSD in MAT file
    for j = 1:size(filename, 2)
        compute_psd(dirpath_subject, filename(j), fileext.mat, dirpath_psd);
    end
end

%{
% TODO: Collect population offline/online GDF filenames
for i = 1:size(subject, 2)
    population_filenames.offline = [population_filenames.offline, subject_filenames{i}.offline];
    population_filenames.online = [population_filenames.online, subject_filenames{i}.online];
end
% TODO: Concatenate population offline GDF files
population_filename.offline = 'population.offline.mi.mi_bhbf';
concatenate_gdf(dirpath_subject, population_filename.offline, fileext.gdf, dirpath_gdf, population_filenames.offline);
% TODO: Concatenate population online GDF files
population_filename.online = 'population.online.mi.mi_bhbf';
concatenate_gdf(dirpath_subject, population_filename.online, fileext.gdf, dirpath_gdf, population_filenames.online);
%}