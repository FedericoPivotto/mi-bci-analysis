%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Load and process each GDF file separately for both calibration and evaluation files, and save the result.

% Dataset
dataset = 'micontinuous_small';
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
    subject_filepaths{i}.offline = [];
    subject_filepaths{i}.online = [];
    for j = 1:size(filename, 2)
        % Save offline/online GDF filename
        filepath = strcat(dirpath_subject, filename(j), fileext.gdf);
        if(contains(filename(j), 'offline'))
            subject_filepaths{i}.offline = [subject_filepaths{i}.offline, filepath];
        elseif(contains(filename(j), 'online'))
            subject_filepaths{i}.online = [subject_filepaths{i}.online, filepath];
        end
    end

    % Directory in which save concatenations in MAT file
    dirpath_gdf = strcat('gdf/', dataset, '/', subject(i), '/');

    % Concatenate and save offline GDF files
    subject_filename.offline = strcat(subject_id, '.offline.mi.mi_bhbf');
    concatenate_gdf(subject_filename.offline, dirpath_gdf, subject_filepaths{i}.offline);
    
    % Concatenate and save online GDF files
    subject_filename.online = strcat(subject_id, '.online.mi.mi_bhbf');
    concatenate_gdf(subject_filename.online, dirpath_gdf, subject_filepaths{i}.online);
end

% Collect population offline/online GDF filenames
population_filepaths.offline = [];
population_filepaths.online = [];
for i = 1:size(subject, 2)
    population_filepaths.offline = [population_filepaths.offline, subject_filepaths{i}.offline];
    population_filepaths.online = [population_filepaths.online, subject_filepaths{i}.online];
end
% Directory in which save the concatenations
dirpath_gdf = strcat('gdf/', dataset, '/population/');
% Concatenate population offline GDF files
population_filename.offline = 'population.offline.mi.mi_bhbf';
concatenate_gdf(population_filename.offline, dirpath_gdf, population_filepaths.offline);
% Concatenate population online GDF files
population_filename.online = 'population.online.mi.mi_bhbf';
concatenate_gdf(population_filename.online, dirpath_gdf, population_filepaths.online);

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
    dirpath_gdf = strcat('gdf/', dataset, '/');
    dirpath_subject = cell2mat(strcat(dirpath_gdf, subject(i), '/'));
    files = dir(fullfile(dirpath_subject, ['*', fileext.mat]));
    filename = strrep({files.name}, fileext.mat, '');
    % Process each MAT file and save PSD in MAT file
    for j = 1:size(filename, 2)
        compute_psd(dirpath_subject, filename(j), fileext.mat, dirpath_psd);
    end
end

% Directory in which save the PSD
dirpath_psd = strcat('psd/', dataset, '/population/');
% Get MAT files in population directory
dirpath_population = strcat('gdf/', dataset, '/population/');
files = dir(fullfile('gdf', dataset, 'population', ['*', fileext.mat])); % dirpath_population, ['*', fileext.mat]));
filename = strrep({files.name}, fileext.mat, '');
% Process each MAT file and save PSD in MAT file
for i = 1:size(filename, 2)
    compute_psd(dirpath_population, filename(i), fileext.mat, dirpath_psd);
end