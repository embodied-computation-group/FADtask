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
% Last edit: 16/06/2020


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
    [scr.win, scr.winRect] = PsychImaging('OpenWindow', scr.screenID, scr.BackgroundGray); %,[0 0 1920 1080] mr screen dim
    PsychColorCorrection('SetEncodingGamma', scr.win, 1/scr.GammaGuess);
    % Set text size, dependent on screen resolution
    if any(logical(scr.winRect(:)>4000))       % 4K resolution
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
    ValidTrial = zeros(1,2);
    vars.RunSuccessfull = 0;
    vars.Aborted = 0;
    vars.Error = 0;
    WaitSecs(0.1);
    GetSecs;
    Resp = 888;
    ConfRating = 888;
    WaitSecs(0.500);
    [~, ~, KeyCode] = KbCheck;
    
    %% Initialise EyeLink
    if useEyeLink
        
        dummymode = 0;
        
        vars.EyeLink = 1;
        
        % check for eyelink data dir
        if ~exist('./data/eyelink', 'dir')
            mkdir('./data/eyelink')
        end
        
        if (Eyelink('Initialize') ~= 0); return;
            fprintf('Problem initializing eyelink\n');
        end
        
        
        % STEP 2
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        el = EyelinkInitDefaults(scr.win);
        
        % STEP 3
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(dummymode)
            fprintf('Eyelink Init aborted.\n');
            cleanup;  % cleanup function
            return;
        end
        
        [v, vs] = Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
        
        % open file for recording data
        %cd to data/eyelink
        edfFile = 'demo.edf';
        Eyelink('Openfile', edfFile);
        
        % open file to record data to [dos-style naming, i.e. max 8 letters]
        fname = [num2str(vars.subNo)];
        DateTimeStrDOS = datestr(now,'ddmmHH');
        eyelinkDataName = [fname, '.edf'];
        status = Eyelink('Openfile', eyelinkDataName);
        % if we can't open an edf file
        if (status < -1)
            fprintf('Error creating EDF file! Setting filename to default (datetime.edf).');
            eyelinkDataName = [DateTimeStrDOS '.edf'];
            status = Eyelink('Openfile', eyelinkDataName);
        end
        
        % STEP 4
        % Do setup and calibrate the eye tracker
        EyelinkDoTrackerSetup(el);
        
        % do a final check of calibration using driftcorrection
        % You have to hit esc before return.
%         EyelinkDoDriftCorrection(el);
        
    end
    
    %% EyeLink: Just before display loop
    if useEyeLink
        
        % Set parameters for velocity, acceleration and motion thresholds for
        % saccade detection in eyelink
        % These are to detect larger saccades, no microsaccades
        SaccVelocityThreshold = 30;             % 40(22deg allows detection of saccades of 0.3deg amplitude; larger threshold reduces number of microsaccades detected) ( 22 [Zimmermann et al] vs. 40 [Collins et al.])
        SaccAccelerationThreshold = 8000;       % 3000 [Collins et al] & 4000 [zimmermann et al.]
        SaccMotionThreshold = 0;                % 0.5/ 0.15 [Collins et al] (not useful if planning to use averages, so try without first.
        
        % before Eyelink('StartRecording')
        eyelinkParsVelocity = ['saccade_velocity_threshold = ' num2str(SaccVelocityThreshold)];
        eyelinkParsAcceleration = ['saccade_acceleration_threshold = ' num2str(SaccAccelerationThreshold)];
        eyelinkParsMotion = ['saccade_motion_threshold = ' num2str(SaccMotionThreshold)];
        
        % Set Parameters to detect larger saccades only, no microsaccades
        Eyelink('command', eyelinkParsVelocity);        % 30deg/sec - for smaller saccades
        Eyelink('command', eyelinkParsAcceleration);    % 8000 deg/sec2 - for larger saccades
        Eyelink('command', eyelinkParsMotion);          % 0 degree - allow calculating statistics for saccadic duration, amplitude and avg velocity
        
        % Send the paramters out to be written to the results file.
        Eyelink('message', eyelinkParsVelocity);
        Eyelink('message', eyelinkParsAcceleration);
        Eyelink('message', eyelinkParsMotion);
        
        DisplayResolution = ['DisplayResolution width ' num2str(scr.MonitorWidth) ' height ' num2str(scr.MonitorHeight)];
        Eyelink('message', DisplayResolution);
        
        paradigmText = ['Paradigm: EyeLink data for ', vars.exptName];
        Eyelink('message', paradigmText);
        
        % Start recording
        status = Eyelink('StartRecording');
        if status~=0
            error('startrecording error, status: ',status)
        end
        
        eye_used = Eyelink('EyeAvailable');             % Which eye are we tracking
        if eye_used == el.BINOCULAR                     % if both eyes are tracked
            eye_used = el.LEF5T_EYE;                     % which eye
        end
        
    end
    
    
    tic
    
    %% Show task instructions
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, [vars.InstructionTask], 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    
    
    while KeyCode(keys.Trigger) == 0                                    % Wait for trigger
        [~, ~, KeyCode] = KbCheck;
        WaitSecs(0.001);
    end
    
    if useEyeLink
        Eyelink('message','STARTEXP');
    end
    
    %% Run through trials
    
    WaitSecs(0.500);            % pause before experiment start
    thisTrial = 1;              % trial counter
    endOfExpt = 0;
    
    while endOfExpt ~= 1       % General stop flag for the loop
        
        if useEyeLink
            % EyeLink:  this trial
            startStimText = ['Trial ' num2str(thisTrial) ' starts now'];
            Eyelink('message', startStimText); % Send message
        end
        
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
        
        if useEyeLink
            % EyeLink:  face on
            startStimText = ['Trial ' num2str(thisTrial) ' face stim on'];
            Eyelink('message', startStimText); % Send message
        end
        
        % While loop to show stimulus until StimT seconds elapsed.
        while (GetSecs - StimOn) <= vars.StimT
            
            % KbCheck for Esc key
            if KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
            
            [~, ~, KeyCode] = KbCheck;
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
        
        [~, StartRT] = Screen('Flip', scr.win);
        
        if useEyeLink
            % EyeLink:  face response
            startStimText = ['Trial ' num2str(thisTrial) ' face response screen on'];
            Eyelink('message', startStimText); % Send message
        end
        
        % loop until valid key is pressed or RespT is reached
        while ((GetSecs - StartRT) <= vars.RespT)
            
            switch vars.InputDevice
                
                case 1 % Keyboard response
                    
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
                        Results.EmoResp(thisTrial) = 9;
                        % Save, mark the run
                        vars.RunSuccessfull = 0;
                        vars.Aborted = 1;
                        experimentEnd(vars, scr, keys, Results, stair);
                        return
                    else
                        % ? DrawText: Please press a valid key...
                    end
                    
                    [~, EndRT, KeyCode] = KbCheck;
                    WaitSecs(0.001);
                    
                    
                case 2 % Mouse
                    
                    [~,~,buttons] = GetMouse;
                    while ~any(buttons) % wait for press
                        [~,~,buttons] = GetMouse; % L [1 0 0], R [0 0 1]
                    end
                                        
                    if buttons == [1 0 0] % Left - angry
                        % update results
                        Resp = 0;
                        ValidTrial(1) = 1;
                        
                    elseif buttons == [0 0 1] % Right - happy
                        % update results
                        Resp = 1;
                        ValidTrial(1) = 1;
                        
                    else
                        
                    end
                    
                    EndRT = GetSecs;                                % ### check RT for mouseclick ###
            end
            
            if(ValidTrial(1)), WaitSecs(0.2); break; end
        end
        
        % Brief feedback                                            % ### change to * on response promp screen ###
        if Resp% happy
            emotString = 'Happy';
        else
            emotString = 'Angry';
        end
        feedbackString = ['Response recorded: ', emotString];
        Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
        DrawFormattedText(scr.win, feedbackString, 'center', 'center', scr.TextColour);
        [~, ~] = Screen('Flip', scr.win);
        WaitSecs(0.25);
        disp(feedbackString);
        
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
            
            switch vars.InputDevice
                
                case 1 % Keyboard response
                    
                    % Rate confidence: 1 Unsure, 2 Sure, 3 Very sure
                    
                    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
                    DrawFormattedText(scr.win, [vars.InstructionConf], 'center', 'center', scr.TextColour);
                    [~, StartConf] = Screen('Flip', scr.win);
                    
                    if useEyeLink
                        % EyeLink:  conf rating
                        startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                        Eyelink('message', startStimText); % Send message
                    end
                    
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
                            Results.ConfResp(thisTrial) = 9;
                            % Save, mark the run
                            vars.RunSuccessfull = 0;
                            vars.Aborted = 1;
                            experimentEnd(vars, scr, keys, Results, stair);
                            return
                        else
                            % DrawText: Please press a valid key...
                        end
                        
                        [~, EndConf, KeyCode] = KbCheck;
                        WaitSecs(0.001);
                        
                        % Compute response time
                        ConfRatingT = (EndConf - StartConf);
                        
                    end
            
                case 2 % Mouse response
                    
                    if useEyeLink
                        % EyeLink:  conf rating
                        startStimText = ['Trial ' num2str(thisTrial) ' confidence screen on'];
                        Eyelink('message', startStimText); % Send message
                    end
                    
                    [position, RT, answer] = slideScale(scr.win, ...
                        vars.InstructionConf, ...
                        scr.winRect, ...
                        vars.ConfEndPoins, ...
                        'device', 'mouse', ...
                        'stepsize', 10, ...
                        'responseKeys', [KbName('return') KbName('LeftArrow') KbName('RightArrow')], ...
                        'startposition', 'center', ...
                        'range', 2);
                    
                    % update results
                    ConfRating = position;
                    ConfRatingT = RT;
                    
                    if answer
                    ValidTrial(2) = 1; end
                    
            end
            
            % If this trial was successfull, move on...
            if(ValidTrial(2)), WaitSecs(0.2); end
 
            % Write trial result to file
            Results.ConfResp(thisTrial) = ConfRating;
            Results.ConfRT(thisTrial) = ConfRatingT;
            
            disp(['Confidence recorded: ', num2str(ConfRating)]);
            
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
        
        if useEyeLink
            % EyeLink:  ITI
            startStimText = ['Trial ' num2str(thisTrial) ' ITI start'];
            Eyelink('message', startStimText); % Send message
        end
        
        % Present the gray screen for ITI duration
        while (GetSecs - StartITI) <= vars.ITI(thisTrial)
            
            if KeyCode(keys.Escape)==1
                % Save, mark the run
                vars.RunSuccessfull = 0;
                vars.Aborted = 1;
                experimentEnd(vars, scr, keys, Results, stair);
                return
            end
        end
        
        [~, ~, KeyCode] = KbCheck;
        WaitSecs(0.001);
        
        % Advance one trial (always in MR)
        thisTrial = thisTrial + 1;
        
%         % if this was a valid trial, advance one. Else, repeat it.
%         if ValidTrial(1)            % face affect rating
%             thisTrial = thisTrial + 1;
%         else
%             disp('Invalid response. Repeating trial.');
%             % Repeat the trial...
%         end
        
        % Reset Texture, ValidTrial, Resp
        ValidTrial = zeros(1,2);
        Resp = NaN;
        ConfRating = NaN;
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
            
            while KeyCode(keys.Space) == 0
                [~, ~, KeyCode] = KbCheck;
                WaitSecs(0.001);
            end
            
        end
        
        
    end%thisTrial
    
    vars.RunSuccessfull = 1;
    
    % Save, mark the run
    experimentEnd(vars, scr, keys, Results, stair);

    toc
    
    %% EyeLink: experiment end
    if useEyeLink
        Eyelink('message', 'ENDEXP');
        
        % Stop recording
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        
        % Transfer data from the host PC and afterwards stop EyeLink
        
        % Copy EDF file from Host computer to other directory for further analysis.
        status = Eyelink('ReceiveFile', eyelinkDataName, [fname '.edf'], []);
        if (status < -1)
            fprintf('Error transferring EDF file to local directory!');
        end
        Eyelink('ShutDown');
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
