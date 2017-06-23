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
        ALLEEG = []; CURRENTSET = 1;
        
        if exist(sprintf('%s_%s.set', fileID, PreProcConstants.error),'file') % Only do these steps if an error file doesn't already exist
            fprintf('\n\nError file exists for %s... Skipping.\n\n', fileID);
            continue
        end
        
        %% Pre epoch steps
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{1}),'file') &&  any(ismember(analysisSelections,1))% Only do these steps if the PreEpoch file doesn't already exist
            
            fprintf('\n\n%s - Starting %s...\n\n',datestr(now),fileID);
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
               
            [EEG, warn] = func_checkEvents(EEG);                           % Check and fix event codes
            
            if warn % If there is something dodgy with the event markers then save the data under a different name for inspection
                EEG.log = [EEG.log; sprintf('%s - Event codes are weird: Recheck', datestr(now, 13))];
                EEG     = func_saveData(EEG, PreProcConstants.error);
                fprintf('\n\n%s - Skipping rest of pipeline for %s\n\n', datestr(now), fileID)
                continue
            else    % Otherwise place it in the PreEpoch folder in prep for Epoching and ICA
                EEG.log = [EEG.log; sprintf('%s - Event codes checked', datestr(now, 13))];
            end
            
            % Separate EMG channels
            EEG.EMG = pop_select(EEG, 'channel', PreProcConstants.EMG_chans);
            EEG     = pop_select(EEG, 'nochannel', PreProcConstants.EMG_chans);
            EEG.log = [EEG.log; sprintf('%s - EMG Channels separated', datestr(now, 13))];
            
            if ~any(ismember({EEG.chanlocs.labels}, 'VEOG'))               % Create single VEOG Chan for ICA
                VEOG_n = length(EEG.data(:,1))+1;
                EEG.data(VEOG_n,:) = EEG.data(PreProcConstants.VEOG_chans(1),:) - EEG.data(PreProcConstants.VEOG_chans(2),:);
                EEG.nbchan = size(EEG.data,1);
                if ~isempty(EEG.chanlocs)
                    EEG.chanlocs(VEOG_n).labels = 'VEOG';
                end
                clear VEOG_n
                EEG.log = [EEG.log; sprintf('%s - VEOG channel added', datestr(now,13))];
            end
                     
            
            EEG     = func_saveData(EEG, PreProcConstants.outputs{1});
            
            fprintf('\n\n%s - Pre-epoching for %s complete\n\n', datestr(now), fileID)
                  
        end
        
        %% Filter and epoch steps
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{2}),'file') && any(ismember(analysisSelections,2))
            
            try
                func_checkAndLoad(fileID, 1);
            catch err
                func_warning(err.message)
                continue
            end        
            
            EEG         = pop_eegfiltnew(EEG, PreProcConstants.HP_cutoff_EEG, 0);
            EEG.log     = [EEG.log; sprintf('%s - EEG High-pass filtered at %d', datestr(now, 13), PreProcConstants.HP_cutoff_EEG)];
        
            EEG         = pop_epoch( EEG, {60001}, PreProcConstants.ICAepochLength); % Epoch the data
            EEG.log     = [EEG.log; {sprintf('%s - Data epoched for ICA', datestr(now, 13))}];
        
            EEG = func_saveData(EEG, PreProcConstants.outputs{2});
        end
        
        %% ICA step
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{3}),'file') && any(ismember(analysisSelections,3))

            try
                func_checkAndLoad(fileID, 2);
            catch err
                func_warning(err.message)
                continue
            end
            
            fprintf('\n%s - Starting ICA...\n\n',datestr(now));
            
            try % Try to run ICA
                EEG = pop_runica(EEG, 'extended', 1,'verbose', 'on', 'chanind', [EEG.include find(ismember({EEG.chanlocs.labels}, 'VEOG'))]); % Run ICA
            catch
                fprintf('\n\nVEOG channel not found... Skipping...\n\n');
                continue
            end
        
            EEG.log = [EEG.log; {sprintf('%s - ICA Completed', datestr(now, 13))}];
        
            fprintf('\n%s - Finished ICA...\n\n',datestr(now));
        
            EEG = func_saveData(EEG, PreProcConstants.outputs{3});
        end
        
        %% Reject ICA component step
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{4}),'file') && any(ismember(analysisSelections,4))
            
            try
                func_checkAndLoad(fileID, 3);
            catch err
                func_warning(err.message)
                continue
            end 
            
            
            while ~isempty(EEG.reject) % Loop until component rejection accepted
                EEG = pop_selectcomps(EEG, [1:10]);                                    % Display component maps for rejection
                uiwait(gcf)
            
                EEG = pop_subcomp(EEG, [] , 1);                                        % Remove selected components
            end
            EEG.log = [EEG.log; {sprintf('%s - ICA components removed', datestr(now, 13))}];
            
            EEG = func_saveData(EEG, PreProcConstants.outputs{4});
        end
        
        %% Interpolate bad electrodes & low-pass filter EEG
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{5}),'file') && any(ismember(analysisSelections,5))
            
            try
                func_checkAndLoad(fileID, 4);
            catch err
                func_warning(err.message)
                continue
            end
            
            if isfield(EEG, 'bad_chans')
                EEG.bad_chan_data   = EEG.data(EEG.bad_chans, :,:);                 % Save bad chan data
                EEG                 = pop_interp(EEG, EEG.bad_chans, 'spherical');  % Interpolate bad channels
                EEG.include         = sort([EEG.include EEG.bad_chans]);            % Add bad chans back into include list
                EEG.log             = [EEG.log; {sprintf('%s - Bad chans interpolated', datestr(now, 13))}];
            end
            
            EEG                 = pop_eegfiltnew(EEG, 0, PreProcConstants.LP_cutoff_EEG); % Low pass (40Hz) filter
            EEG.log             = [EEG.log; {sprintf('%s - Low pass filtered at %d Hz', datestr(now, 13), PreProcConstants.LP_cutoff_EEG)}];
            
            EEG                 = func_saveData(EEG, PreProcConstants.outputs{5});
         end
        %% Reject bad epochs
        if ~exist(sprintf('%s_%s.set', fileID, PreProcConstants.outputs{6}),'file') && any(ismember(analysisSelections,6))
            try
                func_checkAndLoad(fileID, 5);
            catch err
                func_warning(err.message)
                continue
            end
            
            
        end

        
        %% Epoch into different conditions
    
        clear EEG ALLEEG
    end
end

% diary('off')
