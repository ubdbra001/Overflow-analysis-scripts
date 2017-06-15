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
    sampleRate = 256;
    
    % set electrode location file
    locFile = 'biosemi64.sph'
    
    % set bad channels file
    badChansFile = 'badChans.mat';
    
    % set cutoff frequencies
    HP_cutoff_EEG = 1
    LP_cutoff_EEG = 35
    
    HP_cutoff_EMG = 10

    ICAepochLength = [-2 17]    % set epoch length for ICA
    epochLength    = [-0.4 5.4] % set epoch length for TFR 
    baselineLength = [-2 0]     % set baseline length

    % Associate event codes with event types
    markers = [60001, 60002, 60003];

    Groups = {'CON', 'DCD'};
    
    outputs = {'PreEpoched','Epoched', 'ICAed', 'ICArejected', 'Interpolated'}
    error = 'Error'
    
    analysisListOptions = {'PromptString','Select steps:',...
                           'SelectionMode','multiple',...
                           'ListString',{'Pre-Epoch','Epoch', 'ICA', 'Reject ICA components', 'Interpolate and LP filter'}}
    
end

end