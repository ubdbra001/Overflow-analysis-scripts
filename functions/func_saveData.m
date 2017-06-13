function EEG = func_saveData(EEG, outputInfo)

if ~exist(outputInfo, 'dir')
    mkdir(outputInfo)
end

EEG     = pop_saveset(EEG, 'filename', sprintf('%s_%s', EEG.origname, outputInfo), 'filepath', outputInfo); % Save dataset
