function avgfft = func_freqTransform(EEG, trialList, chanArray, timeWindow)

fs          = EEG.srate;
fnyq        = fs/2;
nchan       = length(chanArray);
indxtimewin = EEG.times>=timeWindow(1) & EEG.times<=timeWindow(2);
datax       = EEG.data(:,indxtimewin,:);
L           = length(datax); %EEG.pnts;
ntrial      = length(trialList);
NFFT        = 2^nextpow2(L);
f           = fnyq*linspace(0,1,NFFT/2);
ffterp      = zeros(ntrial, NFFT/2, nchan);

for chan_n = 1:nchan
    for trial_n = 1:ntrial
        
%        numbin =[];
        
        y = detrend(datax(chanArray(chan_n),:,trialList(trial_n)));
        Y = fft(y,NFFT)/L;
        ffterp(trial_n,:,chan_n) = abs(Y(1:NFFT/2)).^2; % power
        if rem(NFFT, 2) % odd NFFT excludes Nyquist point
            ffterp(trial_n,2:end,chan_n) = ffterp(trial_n,2:end,chan_n)*2;
        else
            ffterp(trial_n,2:end-1,chan_n) = ffterp(trial_n,2:end-1,chan_n)*2;
        end
    end
end

avgfft = mean(ffterp,1);
avgfft = [f' reshape(avgfft, length(f), nchan)];
