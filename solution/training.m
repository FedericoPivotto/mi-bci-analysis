%% Workspace setup
clc; close all; clear;

%% Function path
addpath('function/');

% function train_model(dirpath_in, filename, fileext, dirpath_out)
% INFO: dirpath_in: 'solution/psd/micontinuous/<subject>/', 'solution/psd/micontinuous/population/'
% INFO: filename: '<filename_without_ext>'
% INFO: fileext: '.mat'
% INFO: dirpath_out: 'solution/model/micontinuous/<subject>/', 'solution/model/micontinuous/population/'

%% Train subjects and population classification models

