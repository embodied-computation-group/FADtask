function experimentLauncher()
%function experimentLauncher()
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT - MRI task
% branch
% Queries participant info, sets paths, and calls main.m
%
% Versions:
%       FAD_v1-1    Pilot 1. MCS procedure, stimuli faces of 4 individuals from KDEF
%       FAD_v1-2    Pilot 2. Adaptive (psi), stimuli two averaged faces (M & F), 
%                   each based on 9 KDEF individuals, OR N-down staircase (4 interleaved stairs)
%       FAD_v1-3    Pilot 3. MRI task, Adaptive (psi), stimuli two averaged faces (M & F)
%
% ======================================================
%
% -------------- PRESS ESC TO EXIT ---------------------
%
% ======================================================
%
% Niia Nikolova
% Last edit: 16/06/2020


%% Initial settings
% Close existing workspace
close all; clc;

devFlag = 0;                % optional flag. Set to 1 when developing the task

vars.exptName = 'FAD_v1-3';


%% Do system checks

% Check that PTB is installed
PTBv = PsychtoolboxVersion;
if isempty(PTBv)
    disp('Please install Psychtoolbox 3. Download and installation can be found here: http://psychtoolbox.org/download');
    return
end

% Skip internal synch checks, suppress warnings
oldLevel = Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

% check working directory & change if necessary
vars.workingDir = fullfile('FADtask_2_Psi');                      % <--- EDIT here as needed ####
currentFolder = pwd;
correctFolder = contains(currentFolder, vars.workingDir);
if ~correctFolder                   % if we're not in the correct working directory, prompt to change
    disp(['Incorrect working directory. Please start from ', vars.workingDir]); return;
end

% check for data dir
if ~exist('data', 'dir')
    mkdir('data')
end

% setup path
addpath(genpath('code'));
addpath(genpath('data'));
addpath(genpath('stimuli'));

%% Ask for subID, age, gender, and display details
if ~devFlag % if we're testing
    
    vars.subNo = input('What is the subject number (given by the experimenter, e.g. 001)?   ');      
%     vars.subAge = input('What is your age (# in years, e.g. 35)?   ');
%     vars.subGen = input('What is your gender (f or m)?   ', 's');
    
%     disp('=====================================================================================');
%     disp('Now please enter your screen dimensions and viewing distance.');
%     disp('If left blank, these will default to 16.5 x 23.5cm, 40cm viewing distance, which is approximate for a 13" laptop.');
%     disp('Press ENTER to continue...');
%     disp('=====================================================================================');
%     pause
%     scr.MonitorHeight = input('Input your monitor height (cm): ');
%     scr.MonitorWidth = input('Input your monitor width (cm): ');
%     scr.ViewDist = input('Input your viewing distance (cm). This is usually around 40cm for laptops, and 75cm for desktop displays: '); 

    scr.ViewDist = 80;
    HideCursor;
else 
    scr.ViewDist = 70;
end

if ~isfield(vars,'subNo') || isempty(vars.subNo)
    vars.subNo = 999;                                               % test
end

%% Output
vars.OutputFolder = fullfile('.', 'data', filesep);
subIDstring = sprintf('%03d', vars.subNo);
vars.DataFileName = strcat(vars.exptName, '_',subIDstring, '_');    % name of data file to write to
if isfile(strcat(vars.OutputFolder, vars.DataFileName, '.mat'))
    % File already exists in Outputdir
    if vars.subNo ~= 999
        disp('A datafile already exists for this subject ID. Please enter a different ID.')
        return
    end
end

 %% Start experiment
main(vars, scr);

% Restore PTB verbosity
Screen('Preference', 'Verbosity', oldLevel);