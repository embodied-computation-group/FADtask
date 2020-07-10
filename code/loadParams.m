%% Define parameters
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Sets key parameters, called by main.m
%
% One Psi staircase starts High, one Low. Data are collapsed accross M&F
% average faces, and gender on each trial is randomized
% ### MCS procedure has not been tested recently
%
% Niia Nikolova
% Last edit: 10/07/2020


%% Key flags
vars.emulate        = 0;                % 0 scanning, 1 testing
vars.ConfRating     = 0;                % Confidence rating? (1 yes, 0 no)
vars.InputDevice    = 2;                % Response method for conf rating. 1 - keyboard 2 - mouse
useEyeLink          = 0;                                                          

vars.Procedure      = 1;                % 1 - Psi method adaptive, doi:https://doi.org/10.1167/13.7.3
                                        % 2 - N-down staircase
                                        % 3 - Method of Constant Stimuli (used in Pilot 1)
vars.RepeatMissedTrials = 0; 


% Get current timestamp & set filename
startTime = clock;      
saveTime = [num2str(startTime(4)), '-', num2str(startTime(5))];
vars.DataFileName = strcat(vars.DataFileName, 'P', num2str(vars.Procedure), '_', date, '_', saveTime); 

%% Procedure
switch vars.Procedure
    case 1 % 1 - Psi method adaptive         
        %% EDIT PARAMETERS BELOW
        %Set up psi
        stair.NumTrials = 30;                               % Number of trials in EACH staircase (2 interleaved staircases, showing M & F faces)               
        vars.NTrialsTotal = stair.NumTrials*2;              % Total N trials differs from stair.NumTrials when we have multiple staircases
        
        stair.grain = 201;                                  % Grain of posterior, high numbers make method more precise at the cost of RAM and time to compute.
        %Always check posterior after method completes [using e.g., :
        %image(PAL_Scale0to1(PM.pdf)*64)] to check whether appropriate
        %grain and parameter ranges were used.
        
        stair.PF = @PAL_Weibull;                            % Assumed psychometric function, e.g. @PAL_Gumbel, @PAL_Logistic, @PAL_Weibull;
        
        %Stimulus values the method can select from       
        stair.stimRange = 0:1:200;
        
        %Define parameter ranges to be included in posterior
        stair.F.priorAlphaRange = 0.01:.5:150;                              % Low start
        stair.M.priorAlphaRange = 50:.5:199;                                % High start
        stair.priorBetaRange = linspace(log10(1),log10(16),stair.grain);    % Use log10 transformed values of beta (slope) parameter in PF   
%         stair.priorBetaRange = 0:.05:5;                                   % non-log10 beta also works 
        stair.priorGammaRange = 0.01;                                       % fixed value (using vector here would make it a free parameter)
        stair.priorLambdaRange = .02;                    
       
        %Initialize PM structure
        % LOW START
        stair.F.PM = PAL_AMPM_setupPM('priorAlphaRange',stair.F.priorAlphaRange,...
            'priorBetaRange',stair.priorBetaRange,...
            'priorGammaRange',stair.priorGammaRange,...
            'priorLambdaRange',stair.priorLambdaRange,...
            'numtrials',stair.NumTrials,...
            'PF' , stair.PF,...
            'stimRange',stair.stimRange);
        
        % HIGH START
        stair.M.PM = PAL_AMPM_setupPM('priorAlphaRange',stair.M.priorAlphaRange,...
            'priorBetaRange',stair.priorBetaRange,...
            'priorGammaRange',stair.priorGammaRange,...
            'priorLambdaRange',stair.priorLambdaRange,...
            'numtrials',stair.NumTrials,...
            'PF' , stair.PF,...
            'stimRange',stair.stimRange);

        
    case 2 % 2 - N-down staircase
        % Staircase parameters
        % Currently, 4 interleaved staircases with high and low starting
        % values for male and female faces
        
        % General 
        vars.NumTrials = 30;                                       % (max trials/stairacse)
        vars.NumDown = 2;                                          % N 'correct' items in a row to go down, after 1st reversal
        vars.StepSize = 2;                                         % Step size 
        vars.ReversalStop = 3;                                     % # of reversals to stop after
        HighStart = 135;                                           % High starting point of staircase 135
        LowStart = 65;                                             % Low starting point of staircase 65

        % Female faces
        vars.ThreshStart = HighStart;                                    
        [stair.F.PMhi] = setupNdownStaircase(vars);
        vars.ThreshStart = LowStart;                                    
        [stair.F.PMlo] = setupNdownStaircase(vars);
        
        % Male faces
        vars.ThreshStart = HighStart;                              
        [stair.M.PMhi] = setupNdownStaircase(vars);
        vars.ThreshStart = LowStart;                              
        [stair.M.PMlo] = setupNdownStaircase(vars);

        vars.NTrialsTotal = vars.NumTrials*4;                  % Max total # of trials = Nstaircases * Ntrials/staircase
        
        
    case 3 % 3 - Method of Constant Stimuli (used in Pilot 1)
        vars.NLevels = 10;                                           % N stimulus levels (face morph)
        vars.NTrials =  12;                                          % per morph level (12 or 7 (with confidence ratings))
        vars.StimIDs = {'f06', 'f24', 'm08', 'm31'};                 % IDs of individuals in stimulus set
        vars.NIndividuals = length(vars.StimIDs);                    % individuals
        vars.NTrialsTotal = vars.NTrials * vars.NLevels * vars.NIndividuals;        % N total trials
        
end


%% Task timing
vars.fixedTiming = 0;       % Flag to force fixed timing for affect response & conf rating. 1 - fixed timing, 2 - self-paced
vars.RepeatMissedTrials = 0;
vars.StimT = 1;      % sec
vars.RespT = 2;      % sec
vars.ConfT = 3;      % sec
vars.ITI_min = 1;    % variable ITI (1-2s)
vars.ITI_max = 2; 
vars.ITI = randInRange(vars.ITI_min, vars.ITI_max, [vars.NTrialsTotal,1]);
vars.PauseFreq = 100;
% if vars.ConfRating 
%     vars.PauseFreq = 50; else
%     vars.PauseFreq = 100; 
% end
singleTrialDuration = vars.StimT + vars.RespT + (vars.ConfT-1) + vars.ITI_max;
vars.sessionDuration = singleTrialDuration * vars.NTrialsTotal;

%% MR params
vars.TR                 = 1.4;           % Seconds per volume
vars.Dummies            = 4;             % Dummy volumes at start
vars.Overrun            = 4;             % Dummy volumes at end
vars.VolsPerExpmt       = round(vars.sessionDuration /vars.TR) + vars.Dummies + vars.Overrun;

if vars.fixedTiming
    disp(['Desired number of volumes: ', num2str(vars.VolsPerExpmt)]);
else
    disp(['Desired number of volumes (upper limit of session duration): ', num2str(vars.VolsPerExpmt)]);
end
disp('Press any key to continue.');
pause;


%% Instructions
switch vars.ConfRating
    
    case 1
        
        switch vars.InputDevice
            
            case 1 % Keyboard
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Then, rate how confident you are in your choice using the number keys. \n \n Unsure (1), Sure (2), and Very sure (3). \n \n The scan will begin soon...';
                vars.InstructionConf = 'Rate your confidence \n \n Unsure (1)     Sure (2)     Very sure (3)';

            case 2 % Mouse
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n Then, rate how confident you are in your choice using the mouse. \n \n Unsure (0), Sure (50), and Very sure (100). \n \n The scan will begin soon...';
                vars.InstructionConf = 'Rate your confidence using the mouse. Left click to confirm.';
                vars.ConfEndPoins = {'0', '100'};
        end
    case 0
        switch vars.InputDevice
            
            case 1 % Keyboard
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n The scan will begin soon...';
            case 2 % Mouse
                vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left button                         HAPPY - Right button \n \n \n \n The scan will begin soon...';
        end
        
end
vars.InstructionQ = 'Angry (L)     or     Happy (R)';
vars.InstructionPause = 'Take a short break... \n \n When you are ready to continue, press ''Space''...';
vars.InstructionEnd = 'You have completed the session. Thank you!';
% N.B. Text colour and size are set after Screen('Open') call


%% Stimuli
% Stimuli
vars.TaskPath = fullfile('.', 'code', 'task');          % from main task folder (ie. 'Pilot_2_PsiAdaptive')
vars.StimFolder = fullfile('.', 'stimuli', filesep);
vars.StimSize = 7;                                      % DVA                                      
vars.StimsInDir = dir([vars.StimFolder, '*.tif']);      % list contents of 'stimuli' folder    

%% MCS task: do some randomising of the stimulus order and, remove sequential duplicates
switch vars.Procedure
    
    case 1 % 1 - Psi method adaptive   
        
        % Interleave High and Low start face staircases                             
        vars.stairSwitch = [zeros(stair.NumTrials, 1); ones(stair.NumTrials, 1)];
        vars.stairSwitch = mixArray(vars.stairSwitch);
             
        % Interleave face genders 
        vars.faceGenderSwitch = [zeros(stair.NumTrials, 1); ones(stair.NumTrials, 1)];
        vars.faceGenderSwitch = mixArray(vars.faceGenderSwitch);
        
    case 2 % 2 - N-down staircase
        
        % Interleave 4 staircases (F-low, F-high, M-low, M-high)
        vars.stairSwitch = [zeros(vars.NumTrials, 1); ones(vars.NumTrials, 1); (ones(vars.NumTrials, 1)).*2 ;  (ones(vars.NumTrials, 1)).*3];
        randomorder = randperm(length(vars.stairSwitch));
        vars.stairSwitch = vars.stairSwitch(randomorder);
        
        
    case 3 % 3 - Method of Constant Stimuli (used in Pilot 1)
        
        % Generate repeating list - string array with filenames & remove
        % sequential duplicate stimuli
        vars.StimList = strings(length(vars.StimsInDir),1);
        for thisStim = 1:length(vars.StimsInDir)
            vars.StimList(thisStim) = getfield(vars.StimsInDir(thisStim), 'name');
        end
        StimTrialList = repmat(vars.StimList,vars.NTrials,1);
        
        % Randomize order of stimuli & move sequential duplicates
        ntrials = length(StimTrialList);
        randomorder = randperm(length(StimTrialList));             % Shuffle 
        vars.StimTrialList = StimTrialList(randomorder);
        
        for thisStim = 1:ntrials-1
            nextStim = thisStim+1;
            Stim_1 = vars.StimTrialList(thisStim);
            Stim_2 = vars.StimTrialList(nextStim);
            
            % if two stim names are identical, move Stim_2 down and remove row
            if strcmp(Stim_1,Stim_2)
                vars.StimTrialList = [vars.StimTrialList; Stim_2];
                vars.StimTrialList(nextStim)=[];
            end
            
        end
end
