function selectFileSubset(NFilesDesired)
% function selectFileSubset
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Select a subset of files from a folder
%
% Niia Nikolova
% Last edit: 01/04/2020

%% Define vars
NFilesPerInd = 200;
NFilesPerInd = NFilesPerInd-1;
NLevels = NFilesDesired;
% StimIDs = {'f06', 'f24', 'm08', 'm31'};     % IDs of individuals in stimulus set
SelectedFilesN = zeros(NLevels, 1);
SelectedFiles = strings(NLevels, 1);        % col array of strings for filenames

% Target directory
TaskPath = fullfile('.', 'code', 'task');   
StimFolder = fullfile(TaskPath, 'stimuli', filesep);
OutputDirName = ['SelectedStimuli_', date];
cd(StimFolder);
mkdir(OutputDirName);

% Decide which files to take
JumpSize = NFilesPerInd ./ (NLevels-1);
for thisJump = 1 : (NLevels-1)
    SelectedFilesN(thisJump+1) = (SelectedFilesN(thisJump) + JumpSize);
end
SelectedFilesN = round(SelectedFilesN);
SelectedFiles = num2str(SelectedFilesN, '%03.f');

% Loop through selected files list
for thisLevel = 1:length(SelectedFilesN)
    searchStringLevel = strcat('*', SelectedFiles(thisLevel, :), '*.tif');
    
    thisLevelFiles = dir(searchStringLevel);
    
    for thisFile = 1:nrows(thisLevelFiles)
        fileName = thisLevelFiles(thisFile).name;
        copyfile(fileName, OutputDirName,'f')
    end
    
end

