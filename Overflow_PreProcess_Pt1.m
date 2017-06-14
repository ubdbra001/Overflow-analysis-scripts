commandwindow;
clear; clc;

% log     = sprintf('CW_log %s - %s.txt', mfilename, datestr(now, 1));      % Generate log filename
% diary(log);                                                               % Start log

addpath(genpath(fileparts(mfilename('fullpath'))))                         % Add dir and subdir of this file to path
PreProcConstants = Overflow_preproccessing_constants;                      % Get constants

analysisSelections = listdlg(PreProcConstants.analysisListOptions{:});     % Decide wich steps to run
if isempty(analysisSelections); error('Nothing selected/User aborted'); end

addpath(genpath(PreProcConstants.dataPath))                                % Add data dir and sub dirs to path
cd(PreProcConstants.dataPath)                                              % Change to data dir

for group = PreProcConstants.Groups
    
    files = dir(sprintf('*%s*.bdf', group{:}));                            % find all files belongning to a particular group
    badChans = load(PreProcConstants.badChansFile, group{:});    
    
    for fileName = {files.name}
        
        [~, fileID, ~] = fileparts(fileName{:});                           % Set File identifier
        
        %% Pre epoch steps
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1}),'file') &&  any(ismember(analysisSelections,1))% Only do these steps if the PreEpoch file doesn't already exist
            
            fprintf('\n%s - Starting %s...\n\n',datestr(now),fileID);
            pause(0.5)
            
            EEG = pop_biosig(fileName{:}, 'ref', PreProcConstants.Ref_chans); % Import BDF file
            EEG.log = {sprintf('%s - Proccessing for %s started', datestr(now, 1), fileID)};
            
            EEG = pop_resample( EEG, PreProcConstants.sampleRate);         % Downsample to 512 Hz
            EEG.log = {sprintf('%s - Resampled to %d Hz', datestr(now, 13), PreProcConstants.sampleRate)};
            
            EEG = pop_chanedit(EEG, 'lookup', PreProcConstants.locFile);   % Add electrode locations
            EEG.log = [EEG.log; sprintf('%s - Electrode location file added', datestr(now, 13))];
            
            [EEG.origname, EEG.setname] = deal(fileID);                    % record original name
            EEG.subject         = str2double(EEG.setname(2:3));            % Set subject number
            
            EEG.include   = 1:64;                                          % Set electrode include list
            
            badChan_temp = badChans.(group{:})(EEG.subject, ~cellfun('isempty', badChans.(group{:})(EEG.subject, :)));
            
            if length(badChan_temp) > 1
                EEG.bad_chans = std_chaninds(EEG, badChan_temp(2:end));    % Convert bad channels from variable to electrode indices for interpolation
                EEG.include(EEG.bad_chans) = [];                               % Remove the bad chans from include list
            end
            
            clear badChan_temp
            
            if ~isfield(EEG, 'VEOG_n')                                     % Create single VEOG Chan for ICA
                EEG.VEOG_n = length(EEG.data(:,1))+1;
                EEG.data(EEG.VEOG_n,:) = EEG.data(PreProcConstants.VEOG_chans(1),:) - EEG.data(PreProcConstants.VEOG_chans(2),:);
                EEG.nbdata = size(EEG.data,1);
                if ~isempty(EEG.chanlocs)
                    EEG.chanlocs(EEG.VEOG_n).labels = 'VEOG';
                end
                EEG.log = [EEG.log; sprintf('%s - VEOG channel added', datestr(now))];
            end
            
            EEG.EMG_rawdata = EEG.data(71:72,:);
            
            [EEG, warn] = func_checkEvents(EEG);                           % Check and fix event codes
            
            if warn % If there is something dodgy with the event markers then save the data under a different name for inspection
                EEG.log = {EEG.log; sprintf('%s - Event codes are weird: Recheck', datestr(now, 13))};
                EEG     = func_saveData(EEG, PreProcConstants.error);
                fprintf('\n\n%s - Skipping rest of pipeline for %s\n\n', datestr(now), fileID)
                continue
            else    % Otherwise place it in the PreEpoch folder in prep for Epoching and ICA
                EEG.log = {EEG.log; sprintf('%s - Event codes checked', datestr(now, 13))};
                EEG     = func_saveData(EEG, PreProcConstants.outputs{1});
            end
            
            fprintf('\n\n%s - Pre-epoching for %s complete\n\n', datestr(now), fileID)
        elseif exist(sprintf('%s_%s.set', fileID, PreProcConstants.error),'file') % Only do these steps if the PreEpoch file doesn't already exist
            fprintf('\n\n Error file already exisits for this... Skipping.\n\n');
            continue
            
        end
        
        %% Filter and epoch steps
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{2}),'file') && any(ismember(analysisSelections,2))
            if ~exist('EEG', 'var') && exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1}),'file')
                fName = sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1});
                EEG = pop_loadset('filename',fName);
            end
        
            EEG.data(1:70,:)   = eegfilt(EEG.data(1:70,:), EEG.srate, PreProcConstants.HP_cutoff_EEG, 0);
            EEG.log            = [EEG.log; sprintf('%s - EEG High-pass filtered at %d', datestr(now, 13), PreProcConstants.HP_cutoff_EEG)];
        
            EEG.data(71:72,:)  = eegfilt(EEG.data(71:72,:), EEG.srate, PreProcConstants.HP_cutoff_EMG, 0);
            EEG.log            = [EEG.log; sprintf('%s - EMG High-pass filtered at %d', datestr(now, 13), PreProcConstants.HP_cutoff_EMG)];
        
            EEG         = pop_epoch( EEG, {60001}, PreProcConstants.ICAepochLength); % Epoch the data
            EEG.log     = [EEG.log; {sprintf('%s - Data epoched for ICA', datestr(now, 13))}];
        
            EEG = func_saveData(EEG, PreProcConstants.outputs{2});
        end
        
        %% ICA step
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{3}),'file') && any(ismember(analysisSelections,3))
            if ~exist('EEG', 'var') && exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{2}),'file')
                fName = sprintf('%s_%s.set', fileID, PreProcConstants.outputs{2});
                EEG = pop_loadset('filename',fName);
            end
            fprintf('\n%s - Starting ICA...\n\n',datestr(now));
        
            EEG     = pop_runica(EEG, 'extended', 1,'verbose', 'off', 'chanind', [EEG.include EEG.VEOG_n]); % Run ICA
            EEG.log = [EEG.log; {sprintf('%s - ICA Completed', datestr(now, 13))}];
        
            fprintf('\n%s - Finished ICA...\n\n',datestr(now));
        
            EEG = func_saveData(EEG, PreProcConstants.outputs{3});
        end
        
        %% Start adding next steps here
    
        clear EEG
    end
end

% diary('off')
