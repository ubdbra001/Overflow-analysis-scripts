
log     = sprintf('CW_log %s - %s.txt', mfilename, datestr(now, 1));       % Generate log filename
diary(log);                                                                % Start log

PreProcConstants = Overflow_preproccessing_constants;

addpath(genpath(PreProcConstants.dataPath))
cd(PreProcConstants.dataPath)

for group = PreProcConstants.Groups
    
    files = dir(sprintf('*%s*.bdf', group{:}));
    % Need to load bad chan file here
    
    for file_n = 1:length(files)
       
        fileName = files(file_n).name;
                 
        fprintf('\n%s - Starting %s...\n\n',datestr(now),fileName);
        pause(1)
        
        EEG = pop_biosig(filename, 'ref', PreProcConstants.Ref_chans);     % Import BDF file
        
        EEG = pop_resample( EEG, PreProcConstants.sampleRate);             % Downsample to 512 Hz
        EEG.log = {sprintf('Resampled to %d Hz - %s', PreProcConstants.sampleRate, datestr(now, 1))};
        
        EEG = pop_chanedit(EEG, 'lookup', PreProcConstants.locationFile);  % Add electrode locations
        EEG.log = {EEG.log; sprintf('Electrode location file added - %s', datestr(now, 1))};
        
        [~, EEG.setname, ~] = fileparts(fileName);                         % Set 
        EEG.subject         = str2double(EEG.setname(2:3));
        
        EEG.include   = 1:64;
        % This one will need editing
        EEG.bad_chans = std_chaninds(EEG, all_bad_chans(EEG.subject,2:end)); % Convert bad channels from xls file to electrode indices for interpolation
        EEG.include(EEG.bad_chans) = [];                                   % Remove bad chans from include list

        if ~isfield(EEG, 'VEOG_n') % Add single VEOG Chan for ICA
            EEG.VEOG_n = length(EEG.data(:,1))+1;
            EEG.data(EEG.VEOG_n,:) = EEG.data(PreProcConstants.VEOG_chans(1),:) - EEG.data(PreProcConstants.VEOG_chans(2),:);
            EEG.nbdata = size(EEG.data,1);
            if ~isempty(EEG.chanlocs)
                EEG.chanlocs(EEG.VEOG_n).labels = 'VEOG';
            end
            EEG.log = {EEG.log; sprintf('VEOG channel added - %s', datestr(now, 1))};
        end
        
        EEG     = pop_eegfilt(EEG, HP_cutoff, []);                         % High pass (0.5 Hz) filter
        EEG.log = {EEG.log; sprintf('High pass filtered at %d - %s', HP_cutoff, datestr(now, 1))};

        
        % This will also need to be checked to ensure it is correct
        EEG     = fix_event_codes(EEG, evnt_codes); % Check and fix event codes
        EEG.log = {EEG.log; sprintf('Event codes checked - %s', datestr(now, 1))};
        EEG     = pop_saveset(EEG, 'filename', sprintf('%s_PreEpoch', EEG.setname), 'filepath', 'PreEpoch\'); % Save dataset
        
        
    end
    
end
