% Present face stimulus for a certain number of seconds
% Easy editing of display params


waitForXSecs = 60;

% Skip internal synch checks, suppress warnings
oldLevel = Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

scr.ViewDist = 80;
pressed = 0;

% Stimuli
vars.TaskPath = fullfile('.', 'code', 'task');          % from main task folder (ie. 'Pilot_2_PsiAdaptive')
vars.StimFolder = fullfile('.', 'stimuli', filesep);
vars.StimSize = 9;                                      % DVA
vars.StimsInDir = dir([vars.StimFolder, '*.tif']);      % list contents of 'stimuli' folder

% Diplay configuration
[scr] = displayConfig(scr);

% Keyboard & keys configuration
[keys] = keyConfig();

AssertOpenGL;

%% Open screen window
[scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);

% Determine stim size in pixels
scr.dist = scr.ViewDist;
scr.width  = scr.MonitorWidth;
scr.resolution = scr.winRect(3);                    % number of pixels of display in horizontal direction
StimSizePix = angle2pix(scr, vars.StimSize);

WaitSecs(0.500);
[~, ~, KeyCode] = KbCheck;

% Determine the stimulus
thisTrialStim = 110;            % double 0-200
thisTrialFileName = ['F_', sprintf('%03d', thisTrialStim), '.tif'];

% Read stim image for this trial into matrix 'imdata'
StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
ImDataOrig = imread(char(StimFilePath));
StimFileName = thisTrialFileName;
ImData = imresize(ImDataOrig, [StimSizePix NaN]);

% Make texture image out of image matrix 'imdata'
ImTex = Screen('MakeTexture', scr.win, ImData);

% Draw texture image to backbuffer
Screen('DrawTexture', scr.win, ImTex);
[~, StimOn] = Screen('Flip', scr.win);

% While loop to show stimulus until StimT seconds elapsed.
while (GetSecs - StimOn) <= waitForXSecs
    
    % KbCheck for Esc key
    if KeyCode(keys.Escape)==1
        % Save, mark the run
        vars.RunSuccessfull = 0;
        vars.Aborted = 1;
        pressed = 1;
        %                 experimentEnd(vars, scr, keys, Results, stair);
        return
    end
    
    [~, ~, KeyCode] = KbCheck;
    WaitSecs(0.001);
    
end

Screen('CloseAll')
% Cleanup at end of experiment - Close window, show mouse cursor, close
% result file, switch back to priority 0
sca;
ShowCursor;
fclose('all');
Priority(0);

% Restore PTB verbosity
Screen('Preference', 'Verbosity', oldLevel);