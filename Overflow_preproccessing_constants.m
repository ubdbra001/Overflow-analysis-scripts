classdef Overflow_preproccessing_constants < handle

properties (Constant)
    % location of raw data
    dataPath = '/Volumes/Samsung/EEG Data/DCD/Hana';

    % Set chans foe external electrodes
    HEOG_chans = [65 66];
    VEOG_chans = [67 68];
    Ref_chans  = [69 70];
    EMG_chans  = [71 72];

    % set sampling rate
    sampleRate = 512;
    
    % set electrode location file
    locFile = 'biosemi64.sph'
    
    % set cutoff frequencies
    HP_cutoff_EEG = 0.5
    LP_cutoff_EEG = NaN
    
    HP_cutoff_EMG = 10

    epochLength = [0 5]        % set epoch length
    baselineLength = [-3 0]    % set baseline length

    % Associate event codes with event types
    markers = [60001, 60002, 60003];

    Groups = {'CON', 'DCD'};
    
    outputs = {'PreEpoch'}
    error = 'Error'
    
end

end