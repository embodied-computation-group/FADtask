function [vars] = ELsetup(scr, vars)
% function [vars] = ELsetup(scr, vars)
%
% Set up EyeLink, runs calibration validation, and starts. 
%
% Input:
%   scr (struct)    must contain screen window handle
%   vars (struct)   " subID
%
% Niia Nikolova
% Last edit: 22/06/2020


dummymode = 0; 

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
vars.ELfname = [num2str(vars.subNo)];
DateTimeStrDOS = datestr(now,'ddmmHH');
vars.eyelinkDataName = [vars.ELfname, '.edf'];
status = Eyelink('Openfile', vars.eyelinkDataName);
% if we can't open an edf file
if (status < -1)
    fprintf('Error creating EDF file! Setting filename to default (datetime.edf).');
    vars.eyelinkDataName = [DateTimeStrDOS '.edf'];
    status = Eyelink('Openfile', vars.eyelinkDataName);
end

% STEP 4
% Do setup and calibrate the eye tracker
EyelinkDoTrackerSetup(el);

% do a final check of calibration using driftcorrection
% You have to hit esc before return.
%         EyelinkDoDriftCorrection(el);


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
    eye_used = el.LEFT_EYE;                     % which eye
end