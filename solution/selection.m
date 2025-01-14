%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

%% Select the most discriminative features for each subject and save them.

% Features manually selected for each subject and population according to their feature maps

% Subject ai6
% Cz: 18, 20, 22
ai6 = [
    frequencies(18), channels({'Cz'}); ...
    frequencies(20), channels({'Cz'}); ...
    frequencies(22), channels({'Cz'}) ...
];

% Subject ai7
% C3: 14
% C4: 14
ai7 = [
    frequencies(14), channels({'C3'}); ...
    frequencies(14), channels({'C4'}) ...
];

% Subject ai8
% Cz: 24
% C3: 14
% C4: 14
ai8 = [
    frequencies(14), channels({'C3'}); ...
    frequencies(14), channels({'C4'}); ...
    frequencies(24), channels({'Cz'}) ...
];

% Subject aj1
% C3: 10, 12
% C4: 10, 12
aj1 = [
    frequencies(10), channels({'C3'}); ...
    frequencies(12), channels({'C3'}); ...
    frequencies(10), channels({'C4'}); ...
    frequencies(12), channels({'C4'})
];

% Subject aj3
% C3: 12, 14
% C4: 12, 14
aj3 = [
    frequencies(12), channels({'C3'}); ...
    frequencies(14), channels({'C3'}); ...
    frequencies(12), channels({'C4'}); ...
    frequencies(14), channels({'C4'}) ...
];

% Subject aj4
% C1: 12, 14
% C3: 12, 14
aj4 = [
    frequencies(12), channels({'C1'}); ...
    frequencies(14), channels({'C1'}); ...
    frequencies(12), channels({'C3'}); ...
    frequencies(14), channels({'C3'}) ...
];

% Subject aj7
% C4: 12
aj7 = [
    frequencies(12), channels({'C4'}) ...
];

% Subject aj9
% C1: 12
% C2: 12
aj9 = [
    frequencies(12), channels({'C1'}); ...
    frequencies(12), channels({'C2'}) ...
];

% Subject population
% C3: 12, 14
% C4: 12, 14
population = [
    frequencies(12), channels({'C3'}); ...
    frequencies(14), channels({'C3'}); ...
    frequencies(12), channels({'C4'}); ...
    frequencies(14), channels({'C4'}) ...
];

% Save selected features in MAT file
dirpath_out = 'resource/';
filename = 'selected_features';
save(char(strcat(dirpath_out, filename, '.mat')), 'ai6', 'ai7', 'ai8', 'aj1', 'aj3', 'aj4', 'aj7', 'aj9', 'population');