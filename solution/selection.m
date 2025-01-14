%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Select the most discriminative features for each subject and save them.

% Features manually selected for each subject and population according to their feature maps

% Subject ai6
% Cz: 18, 20, 22
ai6.channel = {'Cz', 'Cz', 'Cz'};
ai6.frequency = {18, 20, 22};

% Subject ai7
% C3: 14
% C4: 14
ai7.channel = {'C3', 'C4'};
ai7.frequency = {14, 14};

% Subject ai8
% Cz: 24
% C3: 14
% C4: 14
ai8.channel = {'C3', 'C4', 'Cz'};
ai8.frequency = {14, 14, 24};

% Subject aj1
% C3: 10, 12
% C4: 10, 12
aj1.channel = {'C3', 'C3', 'C4', 'C4'};
aj1.frequency = {10, 12, 10, 12};

% Subject aj3
% C3: 12, 14
% C4: 12, 14
aj3.channel = {'C3', 'C3', 'C4', 'C4'};
aj3.frequency = {12, 14, 12, 14};

% Subject aj4
% C1: 12, 14
% C3: 12, 14
aj4.channel = {'C1', 'C1', 'C3', 'C3'};
aj4.frequency = {12, 14, 12, 14};

% Subject aj7
% C4: 12
aj7.channel = {'C4'};
aj7.frequency = {12};

% Subject aj9
% C1: 12
% C2: 12
aj9.channel = {'C1', 'C2'};
aj9.frequency = {12, 12};

% Subject population
% C3: 12, 14
% C4: 12, 14
population.channel = {'C3', 'C3', 'C4', 'C4'};
population.frequency = {12, 14, 12, 14};

% Save selected features in MAT file
dirpath_out = 'resource/';
filename = 'features';
save(char(strcat(dirpath_out, filename, '.mat')), 'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj9', 'population');