% These could all be put in a constants file - Leave for now
mainDataDir = '/Volumes/Samsung/EEG Data/DCD/Hana/';
subDataDir = 'Subepoched';
searchStr = '*.set';
markers = [60001, 60002, 60003];
chanArray = [13, 50];
timeWindow = [0 5000];
hands = {'R', 'L'};

addpath(genpath(fileparts(mfilename('fullpath'))));     % Add paths for scripts

cd(mainDataDir)            % Change current dir to main data directory
addpath(subDataDir)        % Add data dir of interest to path
files = dir(fullfile(subDataDir, searchStr)); % Find all .set files in data dir of interest

for fileName = {files.name} % Loop through each file found
    
        EEG2 = pop_loadset('filename',fileName); % Load the file
        
        for marker = markers % For each marker
            
            EEG = EEG2.(sprintf('marker_%d',marker));   % Load the EEG data associated with that marker
            EEG.activeHand = EEG2.activeHand;           % Insert details about which hand was used
            
            for hand = hands % Loop through each of the hands
                trialList = find(ismember(EEG2.activeHand, hand{:}));  % Generate a list of trials with that hand as the dominant one
                EEG.freqTransform.(hand{:}) = func_freqTransform(EEG, trialList, chanArray, timeWindow); % Generate average frequency spectrum for those trials
            end
            
            % Put the data back into the main variable
            EEG2.(sprintf('marker_%d',marker)) = EEG;
            clear EEG
        end
        
        % Save EEG file
        EEG = func_saveData(EEG2, 'freqTransformed');
end
