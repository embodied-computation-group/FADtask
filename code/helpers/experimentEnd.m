function experimentEnd(vars, scr, keys, Results, stair)
%function experimentEnd(vars, scr, keys, Results, stair)

% clean up the stair structure & sub-structures (delete objects and 5D vars)
% fields = {'PF'};
% stair = rmfield(stair,fields);
% fields = {'PF', 'LUT', 'posteriorTplus1givenSuccess', 'posteriorTplus1givenFailure'};
% stair.F.PM = rmfield(stair.F.PM, fields);
% fields = {'PF', 'LUT', 'posteriorTplus1givenSuccess', 'posteriorTplus1givenFailure'};
% stair.M.PM = rmfield(stair.M.PM, fields);


if vars.Aborted
    % Abort screen
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, 'Experiment was aborted!', 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(0.5);
    ShowCursor;
    sca;
    disp('Experiment aborted by user!');
    
    % Save, mark the run
    vars.DataFileName = ['Aborted_', vars.DataFileName];
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    disp(['Run was aborted. Results were saved as: ', vars.DataFileName]);
    
    % and as .csv
    Results.stair = stair;                  % Add staircase params to Results struct for the .csv
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);

elseif vars.Error
    % Error
    vars.DataFileName = ['Error_',vars.DataFileName];
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    % and as .csv
    Results.stair = stair;                      % Add staircase structure to Results to save
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);
    
    ShowCursor;
    sca;
    
    disp(['Run crashed. Results were saved as: ', vars.DataFileName]);
    disp(' ** Error!! ***')
    
    % Output the error message that describes the error:
    psychrethrow(psychlasterror);
    
else % Successfull run
    % Show end screen and clean up
    Screen('FillRect', scr.win, scr.BackgroundGray, scr.winRect);
    DrawFormattedText(scr.win, vars.InstructionEnd, 'center', 'center', scr.TextColour);
    [~, ~] = Screen('Flip', scr.win);
    WaitSecs(3);
    
    % Save the data
    save(strcat(vars.OutputFolder, vars.DataFileName), 'stair', 'Results', 'vars', 'scr', 'keys' );
    disp(['Run complete. Results were saved as: ', vars.DataFileName]);
    
    % and as .csv
    Results.stair = stair;                      % Add staircase structure to Results to save
    csvName = strcat(vars.OutputFolder, vars.DataFileName, '.csv');
    struct2csv(Results, csvName);                                       %<----- PsiAdaptive: NOT SAVING .csv due to PF objects in Results struct#####
    
end

sca;
ShowCursor;
fclose('all');
Priority(0);