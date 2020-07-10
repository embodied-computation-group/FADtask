function main(vars, scr)
%function main(vars, scr)
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Main experimental script. Possible to perform different procedures, set
% in loadParams.m
%   1. Psi bayesian adaptive staircase (doi:https://doi.org/10.1167/13.7.3)
%   2. N-down staircase, currently 4 interleaved staircases, 1-up 1-down
%   3. Method of Constant Stimuli
%
% Input:
%   vars        struct with key parameters (most are deifne in loadParams.m)
%   scr         struct with screen / display settings
%
% 16.06.2020        NN added useEyeLink flag to allow gaze recording
%
% Niia Nikolova
% Last edit: 10/07/2020


% Load the parameters
loadParams;

% Results struct
DummyDouble = ones(vars.NTrialsTotal,1).*NaN;
DummyString = strings(vars.NTrialsTotal,1);
Results = struct('trialN',{DummyDouble},'EmoResp',{DummyDouble}, 'ConfResp', {DummyDouble},...
    'EmoRT',{DummyDouble}, 'ConfRT', {DummyDouble},'trialSuccess', {DummyDouble}, 'StimFile', {DummyString},...
    'MorphLevel', {DummyDouble}, 'Indiv', {DummyString}, 'SubID', {DummyDouble},...
    'Triggers', {DummyDouble}, 'SOT_trial', {DummyDouble},...
    'SOT_face', {DummyDouble}, 'SOT_EmoResp', {DummyDouble}, 'SOT_ConfResp', {DummyDouble},...
    'SOT_ITI', {DummyDouble}, 'TrialDuration', {DummyDouble});
% col_trialN = 1;
% col_EmoResp = 2;
% col_ConfResp = 3;
% col_EmoRT = 4;
% col_ConfRT = 5;
% col_trialSuccess = 6;
% col_StimFile = 7;
% col_MorphLevel = 8;
% col_Indiv = 9;            M or F for PsiAdaptive
% col_subID = 10;


% Diplay configuration
[scr] = displayConfig(scr);

% Keyboard & keys configuration
[keys] = keyConfig();

% Reseed the random-number generator
SetupRand;


%% Prepare to start
AssertOpenGL;       % OpenGL? Else, abort

try
    %% Open screen window
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
    % Set text size, dependent on screen resolution
    if any(logical(scr.winRect(:)>3000))       % 4K resolution
        scr.TextSize = 65;
    else
        scr.TextSize = 28;
    end
    Screen('TextSize', scr.win, scr.TextSize);
    
    % Set priority for script execution to realtime priority:
    scr.priorityLevel = MaxPriority(scr.win);
    Priority(scr.priorityLevel);
    
    % Determine stim size in pixels
    scr.dist = scr.ViewDist;
    scr.width  = scr.MonitorWidth;
    scr.resolution = scr.winRect(3);                    % number of pixels of display in horizontal direction
    StimSizePix = angle2pix(scr, vars.StimSize);
    
    % Dummy calls to prevent delays
    vars.ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    vars.Aborted = 0;
    vars.Error = 0;
    WaitSecs(0.1);
    GetSecs;
    vars.Resp = 888;
    vars.ConfResp = 888;
    vars.abortFlag = 0;
    WaitSecs(0.500);
    [~, ~, keys.KeyCode] = KbCheck;
      
    %% Initialise EyeLink
    if useEyeLink
        vars.EyeLink = 1;
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        [vars] = ELsetup(scr, vars);
    end

    
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    
    new_line;
    disp('Waiting for trigger.'); new_line;
    
    while keys.KeyCode(keys.Trigger) == 0                                    % Wait for trigger
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    Results.FirstTriggerT = GetSecs;
    
%      If scanning, wait for dummy volumes
    if ~vars.emulate
        WaitSecs(vars.TR*vars.Dummies);end
    
    Results.SessionStartT = GetSecs;            % session start = trigger 1 + dummy vols
    
    if useEyeLink
        Eyelink('message','STARTEXP');
    end
    
    
    tic
    
    %% Run through trials
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    endOfExpt = 0;
    
    while endOfExpt ~= 1       % General stop flag for the loop
        
        Results.SOT_trial(thisTrial) = GetSecs;
        if useEyeLink
            % EyeLink:  this trial
            startStimText = ['Trial ' num2str(thisTrial) ' starts now'];
            Eyelink('message', startStimText); % Send message
        end
        
        % Determine which stimulus to present, read in the image, adjust size and show stimulus
        switch vars.Procedure
            case 1 % 1 - Psi method adaptive
                
                % Which gender face to present on this trial?
                switch vars.faceGenderSwitch(thisTrial)
                    case 0
                        thisTrialGender = 'F_';
                    case 1
                        thisTrialGender = 'M_';
                end
                
                switch vars.stairSwitch(thisTrial)
                    case 0                                              % Low start staircase
                        thisTrialStim = stair.F.PM.xCurrent;            % double 0-200 
                    case 1                                              % High start staircase
                        thisTrialStim = stair.M.PM.xCurrent;
                end
                
                thisTrialFileName = [thisTrialGender, sprintf('%03d', thisTrialStim), '.tif'];
                disp(['Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
                
                
            case 2 % 2 - N-down staircase
                switch vars.stairSwitch(thisTrial)
                    case 0 % Female high
                        stair.F.PMhi.x = [stair.F.PMhi.x, stair.F.PMhi.xCurrent];
                        thisTrialStim = stair.F.PMhi.xCurrent;            % double 0-200
                        thisTrialFileName = ['F_', sprintf('%03d', thisTrialStim), '.tif'];
                        disp(['Stair 0, F hi. ','Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
                        
                    case 1 % Female low
                        stair.F.PMlo.x = [stair.F.PMlo.x, stair.F.PMlo.xCurrent];
                        thisTrialStim = stair.F.PMlo.xCurrent;            % double 0-200
                        thisTrialFileName = ['F_', sprintf('%03d', thisTrialStim), '.tif'];
                        disp(['Stair 1, F lo. ','Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
                        
                    case 2  % Male high
                        stair.M.PMhi.x = [stair.M.PMhi.x, stair.M.PMhi.xCurrent];
                        thisTrialStim = stair.M.PMhi.xCurrent;            % double 0-200
                        thisTrialFileName = ['M_', sprintf('%03d', thisTrialStim), '.tif'];
                        disp(['Stair 2, M hi. ','Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
                        
                    case 3 % Male low
                        stair.M.PMlo.x = [stair.M.PMlo.x, stair.M.PMlo.xCurrent];
                        thisTrialStim = stair.M.PMlo.xCurrent;            % double 0-200
                        thisTrialFileName = ['M_', sprintf('%03d', thisTrialStim), '.tif'];
                        disp(['Stair 3, M lo. ','Trial # ', num2str(thisTrial), '. Stim: ', thisTrialFileName]);
                end
        end%procedure
        
        % Read stim image for this trial into matrix 'imdata'
        StimFilePath = strcat(vars.StimFolder, thisTrialFileName);
        ImDataOrig = imread(char(StimFilePath));
        StimFileName = thisTrialFileName;
        ImData = imresize(ImDataOrig, [StimSizePix NaN]);           % Adjust image size to StimSize dva in Y dir
  
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('DrawTexture', scr.win, ImTex);
        [~, StimOn] = Screen('Flip', scr.win);
        
        Results.SOT_face(thisTrial) = GetSecs;
        if useEyeLink
            % EyeLink:  face on
            startStimText = ['Trial ' num2str(thisTrial) ' face stim on'];
            Eyelink('message', startStimText); % Send message
        end
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % KbCheck for Esc key
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            
            [~, ~, keys.KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        if useEyeLink
            % EyeLink:  face off
            startStimText = ['Trial ' num2str(thisTrial) ' face stim off'];
            Eyelink('message', startStimText); % Send message
        end
        
        %% Show emotion prompt screen
        
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        
        [~, vars.StartRT] = Screen('Flip', scr.win);
        
        if useEyeLink
            % EyeLink:  face response
            startStimText = ['Trial ' num2str(thisTrial) ' face response screen on'];
            Eyelink('message', startStimText); % Send message
        end
        
        % Fetch the participant's response, via keyboard or mouse
        [vars] = getResponse(keys, scr, vars);
        
        Results.SOT_EmoResp(thisTrial) = vars.EndRT;
        
        if vars.abortFlag               % Esc was pressed
            Results.EmoResp(thisTrial) = 9;
            % Save, mark the run
            vars.RunSuccessfull = 0;
            vars.Aborted = 1;
            experimentEnd(vars, scr, keys, Results, stair);
            return
        end
        
        % Update staircase, if valid response
        if vars.ValidTrial(1)
            switch vars.Procedure
                
                case 1 % Psi-Adaptive
                    switch vars.stairSwitch(thisTrial)
                        case 0                          % Female avg face
                            stair.F.PM = PAL_AMPM_updatePM(stair.F.PM, vars.Resp);
                        case 1                          % Male avg face
                            stair.M.PM = PAL_AMPM_updatePM(stair.M.PM, vars.Resp);
                    end
                    
                    % Time to stop?
                    if ((stair.F.PM.stop ~= 1) || (stair.M.PM.stop ~= 1))
                        endOfExpt = 0;
                    else
                        endOfExpt = 1;
                    end
                    
                    
                case 2 % N-down
                    switch vars.stairSwitch(thisTrial)
                        case 0 % Female high
                            stair.F.PMhi.response = vars.Resp;
                            [stair.F.PMhi] = updateStaircase(stair.F.PMhi, vars.Resp);
                            
                        case 1 % Female low
                            stair.F.PMlo.response = Resp;
                            [stair.F.PMlo] = updateStaircase(stair.F.PMlo, vars.Resp);
                            
                        case 2 % Male high
                            stair.M.PMhi.response = Resp;
                            [stair.M.PMhi] = updateStaircase(stair.M.PMhi, vars.Resp);
                            
                        case 3 % Male low
                            stair.M.PMlo.response = Resp;
                            [stair.M.PMlo] = updateStaircase(stair.M.PMlo, vars.Resp);
                            
                    end
                    
                    % Time to stop? (max # trials or all reversals reached)
                    if (thisTrial == vars.NTrialsTotal) || all([stair.F.PMhi.stop, stair.F.PMlo.stop, stair.M.PMhi.stop, stair.M.PMlo.stop])
                        endOfExpt = 1;
                    end
                    
                case 3 % MSC
                    % Time to stop? (max # trials or all reversals reached)
                    if (thisTrial == vars.NTrialsTotal)
                        endOfExpt = 1;
                    end
                    
            end%procedure
        end
        
        % Compute response time
        RT = (vars.EndRT - vars.StartRT);
        
        % Write trial result to file
        Results.EmoResp(thisTrial) = vars.Resp;
        Results.EmoRT(thisTrial) = RT;

        
        
        %% Confidence rating
        if vars.ConfRating
            
            if useEyeLink
                % EyeLink:  conf rating
                startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                Eyelink('message', startStimText);
            end
            
            % Fetch the participant's confidence rating
            [vars] = getConfidence(keys, scr, vars);
            Results.SOT_ConfResp(thisTrial) = vars.ConfRatingT;     
            
            if vars.abortFlag       % Esc was pressed
                Results.ConfResp(thisTrial) = 9;
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            
            % If this trial was successfull, move on...
            if(vars.ValidTrial(2)), WaitSecs(0.2); end
            
            % Write trial result to file
            Results.ConfResp(thisTrial) = vars.ConfResp;
            Results.ConfRT(thisTrial) = vars.ConfRatingT;
            
            % Was this a successfull trial? (both emotion and confidence rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial) == 2);
            
        else % no Confidence rating
            
            % Was this a successfull trial? (emotion rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(vars.ValidTrial(1)) == 1);
            
        end

        %% Update Results
        Results.trialN(thisTrial) = thisTrial;
        Results.StimFile(thisTrial) = StimFileName;
        Results.SubID(thisTrial) = vars.subNo;
        Results.Indiv(thisTrial) = StimFileName(1);
        Results.MorphLevel(thisTrial) = str2double(StimFileName(3:5));
        
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        [~, StartITI] = Screen('Flip', scr.win);
        
        Results.SOT_ITI(thisTrial) = GetSecs;
        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' ITI start'];
            Eyelink('message', startStimText); % Send message
        end
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if keys.KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
        end
        
        [~, ~, keys.KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        Results.TrialDuration(thisTrial) = GetSecs - Results.SOT_trial(thisTrial);

        % If the trial was missed, repeat it or go on...
        if vars.RepeatMissedTrials
            % if this was a valid trial, advance one. Else, repeat it.
            if vars.ValidTrial(1)            % face affect rating
                thisTrial = thisTrial + 1;
            else
                disp('Invalid response. Repeating trial.');
                % Repeat the trial...
            end
        else
            % Advance one trial (always in MR)
            thisTrial = thisTrial + 1;
        end
        
        % Reset Texture, ValidTrial, Resp
        vars.ValidTrial = zeros(1,2);
        vars.Resp = NaN;
        vars.ConfResp = NaN;
        Screen('Close', ImTex);
        
        if useEyeLink
            % EyeLink:  trial end
            startStimText = ['Trial ' num2str(thisTrial) ' ends now'];
            Eyelink('message', startStimText);          % Send message
        end
        
        %% Break every ~5min (vars.PauseFreq trials)
        if ~rem(thisTrial,vars.PauseFreq)
            % Gray screen - Take a short break and press 'space' to
            % continue
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);
            
            disp(['You have completed ', num2str(thisTrial), ' out of ', num2str(vars.NTrialsTotal), ' trials.']);
            
            while keys.KeyCode(keys.Space) == 0
                [~, ~, keys.KeyCode] = KbCheck;
                WaitSecs(0.001);
            end
            
        end
        
        
    end%thisTrial
    
    Results.SessionEndT = GetSecs - Results.SessionStartT;
    vars.RunSuccessfull = 1;
    
    % If scanning, wait for dummy volumes
    if ~vars.emulate
        WaitSecs(vars.TR*vars.Overrun);end
    
    % Save, mark the run
    experimentEnd(vars, scr, keys, Results, stair);
    
    toc
    
    %% EyeLink: experiment end
    if useEyeLink
        ELshutdown(vars)
    end
    
    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch back to priority 0
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    
    disp('Calculating threshold and slope estimates. This will take a few seconds...');
    if vars.Procedure == 1 % Psi-Adaptive
        % Print thresh & slope estimates
        disp(['Threshold estimate, Female face: ', num2str(stair.F.PM.threshold(end))]);
        disp(['Slope estimate, Female face: ', num2str(10.^stair.F.PM.slope(end))]);         % PM.slope is in log10 units of beta parameter
        disp(['Threshold estimate, Male face: ', num2str(stair.M.PM.threshold(end))]);
        disp(['Slope estimate, Male face: ', num2str(10.^stair.M.PM.slope(end))]);
    elseif vars.Procedure == 2 % N-down
        % Print thresh & slope estimates
        disp(['Last stim, Female face (high, low): ', num2str([stair.F.PMhi.x(end), stair.F.PMlo.x(end)])]);
        disp(['Last stim, Male face (high, low): ', num2str([stair.M.PMhi.x(end), stair.M.PMlo.x(end)])]);
        
    end
    
    
catch % Error. Clean up...
    
    % Save, mark the run
    vars.RunSuccessfull = 0;
    vars.Error = 1;
    experimentEnd(vars, scr, keys, Results, stair);
    
end
