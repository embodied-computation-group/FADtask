%% Define parameters
%
% Project: Face Affect Discrimination (FAD) Task, part of CWT
%
% Sets key parameters, called by main.m
%
% ### MCS procedure has not been tested recently
%
% Niia Nikolova
% Last edit: 28/05/2020


%% Key flags
vars.ConfRating = 0;                                         % Confidence rating? (1 yes, 0 no)
vars.Procedure = 1;                                          % 1 - Psi method adaptive, doi:https://doi.org/10.1167/13.7.3
                                                             % 2 - N-down staircase
                                                             % 3 - Method of Constant Stimuli (used in Pilot 1)

                                                             
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
        stair.priorAlphaRange = 0.01:.5:199;
        stair.priorBetaRange = linspace(log10(1),log10(16),stair.grain);    % Use log10 transformed values of beta (slope) parameter in PF   
%         stair.priorBetaRange = 0:.05:5;                                   % non-log10 beta also works 
        stair.priorGammaRange = 0.01;                                       % fixed value (using vector here would make it a free parameter)
        stair.priorLambdaRange = .02;                    
       
        %Initialize PM structure
        % female avg face
        stair.F.PM = PAL_AMPM_setupPM('priorAlphaRange',stair.priorAlphaRange,...
            'priorBetaRange',stair.priorBetaRange,...
            'priorGammaRange',stair.priorGammaRange,...
            'priorLambdaRange',stair.priorLambdaRange,...
            'numtrials',stair.NumTrials,...
            'PF' , stair.PF,...
            'stimRange',stair.stimRange);
        
        % male avg face
        stair.M.PM = PAL_AMPM_setupPM('priorAlphaRange',stair.priorAlphaRange,...
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
vars.StimT = 1;      % sec
vars.RespT = 2;      % sec
vars.ConfT = 5;      % sec
vars.ITI_min = 1;    % variable ITI (1-2s)
vars.ITI_max = 2; 
vars.ITI = randInRange(vars.ITI_min, vars.ITI_max, [vars.NTrialsTotal,1]);
if vars.ConfRating 
    vars.PauseFreq = 50; else
    vars.PauseFreq = 100; 
end

% Instructions
switch vars.ConfRating
    
    case 1
        vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Then, rate how confident you are in your choice using the number keys. \n \n Unsure (1), Sure (2), and Very sure (3). \n \n Press ''Space'' to start...';
        vars.InstructionConf = 'Rate your confidence \n \n Unsure (1)     Sure (2)     Very sure (3)';
    
    case 0
        vars.InstructionTask = 'Decide if the face presented on each trial is angry or happy. \n \n ANGRY - Left arrow key                         HAPPY - Right arrow key \n \n \n \n Press ''Space'' to start...';
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
        
        % Interleave M & F face staircases                              <--- ALSO FOUR STAIRCASES?? ###
        vars.stairSwitch = [zeros(stair.NumTrials, 1); ones(stair.NumTrials, 1)];
        randomorder = randperm(length(vars.stairSwitch));
        vars.stairSwitch = vars.stairSwitch(randomorder);
        
        
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
