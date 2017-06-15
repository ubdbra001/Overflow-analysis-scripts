function EEG = func_checkAndLoad(fileID, stepNumber)

fileName = sprintf('%s_%s.set', fileID, Overflow_preproccessing_constants.outputs{stepNumber});

if ~ismember('EEG',evalin('base','who')) && exist(fileName,'file')
    EEG = pop_loadset('filename',fileName);
elseif ~ismember('EEG',evalin('base','who')) && ~exist(fileName,'file')
    error('No EEG variable and no file found. Have you done the preceding steps?')    
end