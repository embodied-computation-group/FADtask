function [vars] = ELshutdown(vars)

Eyelink('message', 'ENDEXP');

% Stop recording
Eyelink('StopRecording');
Eyelink('CloseFile');

% Transfer data from the host PC and afterwards stop EyeLink

% Copy EDF file from Host computer to other directory for further analysis.
status = Eyelink('ReceiveFile', vars.eyelinkDataName, [vars.ELfname '.edf'], []);
if (status < -1)
    fprintf('Error transferring EDF file to local directory!');
end
Eyelink('ShutDown');

end