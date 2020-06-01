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
% Niia Nikolova
% Last edit: 01/06/2020


% Load the parameters
loadParams;

% Results struct
DummyDouble = ones(vars.NTrialsTotal,1).*NaN;
DummyString = strings(vars.NTrialsTotal,1);
Results = struct('trialN',{DummyDouble},'EmoResp',{DummyDouble}, 'ConfResp', {DummyDouble},...
    'EmoRT',{DummyDouble}, 'ConfRT', {DummyDouble},'trialSuccess', {DummyDouble}, 'StimFile', {DummyString},...
    'MorphLevel', {DummyDouble}, 'Indiv', {DummyString}, 'SubID', {DummyDouble});
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
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray);
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
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
    ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    WaitSecs(0.1);
    GetSecs;
    Resp = 888;
    ConfRating = 888;
    WaitSecs(0.500);
    [~, ~, KeyCode] = KbCheck;
    
    
    
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    
    while KeyCode(keys.Space) == 0
        [~, ~, KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    
    
    %% Run through trials
    
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    endOfExpt = 0;

     while endOfExpt ~= 1       % General stop flag for the loop
        
         % Determine which stimulus to present, read in the image, adjust size and show stimulus
        switch vars.Procedure
            case 1 % 1 - Psi method adaptive
                
                switch vars.stairSwitch(thisTrial)
                    case 0                                              % Female avg face                                         
                        thisTrialStim = stair.F.PM.xCurrent;            % double 0-200
                        thisTrialFileName = ['F_', sprintf('%03d', thisTrialStim), '.tif'];
                        
                    case 1                                              % Male avg face
                        thisTrialStim = stair.M.PM.xCurrent;            
                        thisTrialFileName = ['M_', sprintf('%03d', thisTrialStim), '.tif'];
                end
                
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
        
        % Update Results mat
        Results.trialN(thisTrial) = thisTrial;
        Results.StimFile(thisTrial) = StimFileName;
        Results.SubID(thisTrial) = vars.subNo;
        Results.Indiv(thisTrial) = StimFileName(1);
        Results.MorphLevel(thisTrial) = str2double(StimFileName(3:5));    
        
        % Make texture image out of image matrix 'imdata'
        ImTex = Screen('MakeTexture', scr.win, ImData);
        
        % Draw texture image to backbuffer
        Screen('DrawTexture', scr.win, ImTex);
        [~, StimOn] = Screen('Flip', scr.win);
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % KbCheck for Esc key
            if KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.DataFileName = ['Aborted_', vars.DataFileName];
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            
            [~, ~, KeyCode] = KbCheck;
            WaitSecs(0.001);
            
        end
        
        [~, ~] = Screen('Flip', scr.win);            % clear screen
        
        
        %% Show emotion prompt screen
        
        % Angry (L arrow) or Happy (R arrow)?
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, [vars.InstructionQ], 'center', 'center', scr.TextColour);
        
        [~, StartRT] = Screen('Flip', scr.win);
        
        % loop until valid key is pressed or RespT is reached
        while ((GetSecs - StartRT) <= vars.RespT)
            
            % KbCheck for response
            if KeyCode(keys.Left)==1         % Angry
                % update results
                Resp = 0;                   
                ValidTrial(1) = 1;
                               
            elseif KeyCode(keys.Right)==1    % Happy
                % update results
                Resp = 1;
                ValidTrial(1) = 1;

            elseif KeyCode(keys.Escape)==1
                % Save, mark the run
                Resp = 9;
                vars.RunSuccessfull = 0;
                vars.DataFileName = ['Aborted_', vars.DataFileName];
                experimentEnd(vars, scr, keys, Results, stair);
                return
            else
                % ? DrawText: Please press a valid key...          
            end
            
            [~, EndRT, KeyCode] = KbCheck;
            WaitSecs(0.001);
            
            if(ValidTrial(1)), WaitSecs(0.2); break; end
        end
        
        % Update staircase, if valid response
        if ValidTrial(1)
            switch vars.Procedure
                
                case 1 % Psi-Adaptive
                    switch vars.stairSwitch(thisTrial)
                        case 0                          % Female avg face
                            stair.F.PM = PAL_AMPM_updatePM(stair.F.PM, Resp);
                        case 1                          % Male avg face
                            stair.M.PM = PAL_AMPM_updatePM(stair.M.PM, Resp);
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
                            stair.F.PMhi.response = Resp;
                            [stair.F.PMhi] = updateStaircase(stair.F.PMhi, Resp);
                            
                        case 1 % Female low
                            stair.F.PMlo.response = Resp;
                            [stair.F.PMlo] = updateStaircase(stair.F.PMlo, Resp);
                            
                        case 2 % Male high
                            stair.M.PMhi.response = Resp;
                            [stair.M.PMhi] = updateStaircase(stair.M.PMhi, Resp);
                            
                        case 3 % Male low
                            stair.M.PMlo.response = Resp;
                            [stair.M.PMlo] = updateStaircase(stair.M.PMlo, Resp);
                            
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
        RT = (EndRT - StartRT);                                 
        
        % Write trial result to file
        Results.EmoResp(thisTrial) = Resp;
        Results.EmoRT(thisTrial) = RT;
        
        %% Confidence rating
        if vars.ConfRating
            % Rate your confidence: 1 Unsure, 2 Sure, 3 Very sure
            
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);
            [~, StartConf] = Screen('Flip', scr.win);
            
            % loop until valid key is pressed or ConfT is reached
            while (GetSecs - StartConf) <= vars.ConfT
                
                % KbCheck for response
                if KeyCode(keys.One)==1
                    % update results
                    ConfRating = 1;
                    ValidTrial(2) = 1;
                elseif KeyCode(keys.Two)==1
                    % update results
                    ConfRating = 2;
                    ValidTrial(2) = 1;
                elseif KeyCode(keys.Three)==1
                    % update results
                    ConfRating = 3;
                    ValidTrial(2) = 1;
                elseif KeyCode(keys.Escape)==1
                    % Save, mark the run
                    ConfRating = 9;
                    vars.RunSuccessfull = 0;
                    vars.DataFileName = ['Aborted_', vars.DataFileName];
                    experimentEnd(vars, scr, keys, Results, stair);
                    return
                else
                    % DrawText: Please press a valid key...
                end
                
                [~, EndConf, KeyCode] = KbCheck;
                WaitSecs(0.001);
                
                % If this trial was successfull, move on...
                if(ValidTrial(2)), WaitSecs(0.2); break; end
            end
            
            % Compute response time
            ConfRatingT = (EndConf - StartConf);
            
            % Write trial result to file
            Results.ConfResp(thisTrial) = ConfRating;
            Results.ConfRT(thisTrial) = ConfRatingT;
            
            % Was this a successfull trial? (both emotion and confidence rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(ValidTrial) == 2);
            
        else % no Confidence rating
            
            % Was this a successfull trial? (emotion rating valid)
            % 1-success, 0-fail
            Results.trialSuccess(thisTrial) = logical(sum(ValidTrial) == 1);
            
        end
        
        %% ITI / prepare for next trial
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        [~, StartITI] = Screen('Flip', scr.win);
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;              
                vars.DataFileName = ['Aborted_', vars.DataFileName];
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
        end
        
        [~, ~, KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        
        % if this was a valid trial, advance one. Else, repeat it.
        if ValidTrial(1)            % face affect rating
            thisTrial = thisTrial + 1;
        else
            disp('Invalid response. Repeating trial.');
            % Repeat the trial...
        end
        
        % Reset Texture, ValidTrial, Resp
        ValidTrial = zeros(1,2);
        Resp = NaN;
        ConfRating = NaN;
        Screen('Close', ImTex);
        
        %% Break every ~5min (vars.PauseFreq trials)
        if ~rem(thisTrial,vars.PauseFreq)
            % Gray screen - Take a short break and press 'space' to
            % continue
            Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
            DrawFormattedText(scr.win, vars.InstructionPause, 'center', 'center', scr.TextColour);
            [~, ~] = Screen('Flip', scr.win);
            
            disp(['You have completed ', num2str(thisTrial), ' out of ', num2str(vars.NTrialsTotal), ' trials.']);
            
            while KeyCode(keys.Space) == 0
                [~, ~, KeyCode] = KbCheck;
                WaitSecs(0.001);
            end
            
        end
        
    end%thisTrial
    
    
    %% Show end screen and clean up
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, vars.InstructionEnd, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(3);
    
    vars.RunSuccessfull = 1;
    
    % Save the data
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    disp(['Run complete. Results were saved as: ', vars.DataFileName]);
    % and as .csv
    Results.stair = stair;                      % Add staircase structure to Results to save
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);                                       %<----- PsiAdaptive: NOT SAVING .csv due to PF objects in Results struct#####

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
    
    % Cleanup at end of experiment - Close window, show mouse cursor, close
    % result file, switch back to priority 0
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    
catch
    % Error. Clean up...
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    
    % Save the data
    vars.RunSuccessfull = 0;
    vars.DataFileName = ['Error_',vars.DataFileName];
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    % and as .csv
    Results.stair = stair;                      % Add staircase structure to Results to save
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);
    
    disp(['Run crashed. Results were saved as: ', vars.DataFileName]);
    disp(' ** Error!! ***')
    
    % Output the error message that describes the error:
    psychrethrow(psychlasterror);
    
end
