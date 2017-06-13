commandwindow;
clear; clc;

%log     = sprintf('CW_log %s - %s.txt', mfilename, datestr(now, 1));      % Generate log filename
%diary(log);                                                               % Start log

addpath(genpath(fileparts(mfilename('fullpath'))))                         % Add dir and subdir of this file to path
PreProcConstants = Overflow_preproccessing_constants;                      % Get constants

addpath(genpath(PreProcConstants.dataPath))                                % Add data dir and sub dirs to path
cd(PreProcConstants.dataPath)                                              % Change to data dir

for group = PreProcConstants.Groups
    
    files = dir(sprintf('*%s*.bdf', group{:}));                            % find all files belongning to a particular group
    % Need to load bad chan file here
    
    for fileName = {files.name}
       
        [~, fileID, ~] = fileparts(fileName{:});                              % Set File identifier
        
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1}),'file') % Only do these steps if the PreEpoch file doesn't already exist
            
            fprintf('\n%s - Starting %s...\n\n',datestr(now),fileID);
            pause(0.5)

            EEG = pop_biosig(fileName{:}, 'ref', PreProcConstants.Ref_chans); % Import BDF file

            EEG = pop_resample( EEG, PreProcConstants.sampleRate);         % Downsample to 512 Hz
            EEG.log = {sprintf('%s - Resampled to %d Hz', PreProcConstants.sampleRate, datestr(now, 1))};

            EEG = pop_chanedit(EEG, 'lookup', PreProcConstants.locFile);   % Add electrode locations
            EEG.log = [EEG.log; sprintf('%s - Electrode location file added', datestr(now))];

            [EEG.origname, EEG.setname] = deal(fileID);                    % record original name
            EEG.subject         = str2double(EEG.setname(2:3));            % Set subject number

            EEG.include   = 1:64;                                          % Set electrode include list
            % This one will need editing
            EEG.bad_chans = std_chaninds(EEG, all_bad_chans(EEG.subject,2:end)); % Convert bad channels from variable to electrode indices for interpolation
            EEG.include(EEG.bad_chans) = [];                               % Remove the bad chans from include list

            if ~isfield(EEG, 'VEOG_n')                                     % Create single VEOG Chan for ICA
                EEG.VEOG_n = length(EEG.data(:,1))+1;
                EEG.data(EEG.VEOG_n,:) = EEG.data(PreProcConstants.VEOG_chans(1),:) - EEG.data(PreProcConstants.VEOG_chans(2),:);
                EEG.nbdata = size(EEG.data,1);
                if ~isempty(EEG.chanlocs)
                    EEG.chanlocs(EEG.VEOG_n).labels = 'VEOG';
                end
                EEG.log = [EEG.log; sprintf('%s - VEOG channel added', datestr(now))];
            end

            % back up EMG data?

            [EEG, warn] = func_checkEvents(EEG);                           % Check and fix event codes

            if warn % If there is something dodgy with the event markers then save the data under a different name for inspection
                EEG.log = {EEG.log; sprintf('%s - Event codes are weird: Recheck', datestr(now, 1))};
                EEG     = func_saveData(EEG, PreProcConstants.error);
            else    % Otherwise place it in the PreEpoch folder in prep for Epoching and ICA
                EEG.log = {EEG.log; sprintf('%s - Event codes checked', datestr(now, 1))};
                EEG     = func_saveData(EEG, PreProcConstants.outputs{1});
            end
            
            fprintf('\n\n%s - Pre-epoching for %s complete\n\n', datestr(now), fileID)
        elseif exist(sprintf('%s_%s.set', fileID, PreProcConstants.error),'file') % Only do these steps if the PreEpoch file doesn't already exist
            % Work out if this is needed
        else
            fName = sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1});
            EEG = pop_loadset('filename',fName);
        end
        % Add epoch and ICA here
        
    end
    
end

diary('off')
