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

