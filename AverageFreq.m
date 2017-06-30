groups = {'CON', 'DCD'};
markers = [60001, 60002, 60003];
hands = {'R', 'L'};

freqData = struct();

for group = groups
    
    files = dir(sprintf('*%s*.set', group{:}));
    
    for file_n = 1:length(files)
        
        fileName = files(file_n).name;
        
        EEG = pop_loadset('filename',fileName); % Load the file
        IDnumber = str2double(EEG.origname(2:3));
        
        for marker = markers
            
            for hand = hands
                
                freqData.(sprintf('marker_%d',marker)).(hand{:}).(group{:})(file_n,:,:) = EEG.(sprintf('marker_%d',marker)).freqTransform.(hand{:});
                
            end
            
        end

        
    end
    
end

%%

cd('/Volumes/Samsung/EEG Data/DCD/Hana');
load('freqData.mat');

%%

hand = 'R';
marker_n = 3;

groups = {'CON', 'DCD'};

marker = sprintf('marker_6000%d', marker_n);
speed = {'Slow', 'Medium', 'Fast'};

fig = figure('Position', [100, 100, 1200, 800]);

for group_n = 1:length(groups)
    
    
    group = groups{group_n};
    avgfft = mean(freqData.(marker).(hand).(group),1);
    avgfft = reshape(avgfft, 1024, 3);

    sub(group_n) = subplot(1,2,group_n);
    plot(avgfft(:,1),avgfft(:,2),avgfft(:,1),avgfft(:,3))
    xlim([0 50]);
    legend('Channel C3 - Left Hemisphere', 'Channel C4 - Right Hemisphere')
    xlabel('Frequency (Hz)')
    title(sprintf('Group: %s - Hand: %s - Speed: %s', group, hand, speed{marker_n}))
end

linkaxes(sub, 'y')


%%
group = 'DCD';
hand = 'R';
speed = {'Slow', 'Medium', 'Fast'};

fig = figure('Position', [100, 100, 1200, 800]);

for speed_n = 1:length(speed)
    
    marker = sprintf('marker_6000%d', speed_n);
    avgfft = mean(freqData.(marker).(hand).(group),1);
    avgfft = reshape(avgfft, 1024, 3);

    sub(speed_n) = subplot(1,3,speed_n);
    plot(avgfft(:,1),avgfft(:,2),avgfft(:,1),avgfft(:,3))
    xlim([0 50]);
    legend('Channel C3 - Left Hemisphere', 'Channel C4 - Right Hemisphere')
    xlabel('Frequency (Hz)')
    title(sprintf('Group: %s - Hand: %s - Speed: %s', group, hand, speed{speed_n}))    
    
end

linkaxes(sub, 'y')

%%

hand = 'R';

groups = {'CON', 'DCD'};
speed = {'Slow', 'Medium', 'Fast'};
fig = figure('Position', [100, 100, 1200, 800]);

for speed_n = 1:length(speed)
    for group_n = 1:length(groups)
        
        plot_n = ((speed_n-1)*2)+group_n;
        
        marker = sprintf('marker_6000%d', speed_n);
        group  = groups{group_n};
        avgfft = mean(freqData.(marker).(hand).(group),1);
        avgfft = reshape(avgfft, 1024, 3);
    
        
        sub(plot_n) = subplot(length(speed),length(groups), plot_n);
        plot(avgfft(:,1),avgfft(:,2),avgfft(:,1),avgfft(:,3))
        xlim([0 50]);
        legend('Channel C3 - Left Hemisphere', 'Channel C4 - Right Hemisphere')
        xlabel('Frequency (Hz)')
        title(sprintf('Group: %s - Hand: %s - Speed: %s', group, hand, speed{speed_n}))   
        
    end
    
end

linkaxes(sub, 'y')
