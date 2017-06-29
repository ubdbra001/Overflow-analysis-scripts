dataDir = '/Volumes/Samsung/EEG Data/DCD/Hana/SubEpoched';
markers = [60001, 60002, 60003];
chanArray = [13, 50];
timeWindow = [0 5000];

cd(dir)

files = dir('*.set');

for fileName = files.name
    
        EEG2 = pop_loadset('filename',fileName);
        
        for marker = markers
            
            EEG = EEG2.(sprintf('marker_%d',marker));
            EEG.activeHand = EEG2.activeHand;
            
            % Run spectral decomp (looks like welch)
            % Need to modify this to take into account active hand
            
            fs    = EEG.srate;
            fnyq  = fs/2;
            nchan = length(chanArray);
            indxtimewin = ismember_bc2(EEG.times, EEG.times(EEG.times>=timeWindow(1) & EEG.times<=timeWindow(2)));
            datax  = EEG.data(:,indxtimewin,:);
            L      = length(datax); %EEG.pnts;
            ntrial = EEG.trials;
            NFFT   = 2^nextpow2(L);
            f = fnyq*linspace(0,1,NFFT/2);
            ffterp = zeros(ntrial, NFFT/2, nchan);
            
            for k=1:nchan
                for i=1:ntrial
                    numbin =[];
                    
                    y = detrend(datax(chanArray(k),:,i));
                    Y = fft(y,NFFT)/L;
                    ffterp(i,:,k) = abs(Y(1:NFFT/2)).^2; % power
                    if rem(NFFT, 2) % odd NFFT excludes Nyquist point
                        ffterp(i,2:end,k) = ffterp(i,2:end,k)*2;
                    else
                        ffterp(i,2:end-1,k) = ffterp(i,2:end-1,k)*2;
                    end
                end 
            end
            
            % Need to add a way to save this to the EEG file
            
            
        end
    
end
