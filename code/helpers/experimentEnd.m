function experimentEnd(vars, scr, keys, Results, stair)
%function experimentEnd(vars, scr, keys, Results, stair)

% Save, mark the run
vars.RunSuccessfull = 0;
save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
disp(['Run was aborted. Results were saved as: ', vars.DataFileName]);
% and as .csv
Results.stair = stair;                  % add staircase params to Results struct for the .csv
csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
struct2csv(Results ,csvName);

% Abort screen
Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
DrawFormattedText(scr.win, 'Experiment was aborted!', 'center', 'center', scr.TextColour);
[~, ~] = Screen('Flip', scr.win);
WaitSecs(0.5);
ShowCursor;
sca;
disp('Experiment aborted by user!');
return;