%%

rightFirst = 0;

clear d

%%
e = unique([EEG.urevent.type]);
e(2,:) = nan(1, length(e));

for n = 1:length(e)
    e(2,n) = sum(ismember([EEG.urevent.type], e(1,n)));
end

e
%%
a = nan(length(EEG.epoch),1);

for n = 1:length(EEG.epoch)
    if max([EEG.epoch(n).eventurevent{:}]) > 153
        a(n) = (max([EEG.epoch(n).eventurevent{:}])-5)/3;
    elseif max([EEG.epoch(n).eventurevent{:}]) > 122
        a(n) = (max([EEG.epoch(n).eventurevent{:}])-3)/3;        
    else
        a(n) = (max([EEG.epoch(n).eventurevent{:}])-1)/3;
    end
end

a
%%
b = [1:10, 21:30, 41:50]';
c = [11:20, 31:40, 51:60]';

if rightFirst
    d(ismember(a, b)) = {'R'};
    d(ismember(a, c)) = {'L'};
else
    d(ismember(a, b)) = {'L'};
    d(ismember(a, c)) = {'R'}; 
end

d'

%%
EEG.activeHand = d';

EEG = func_saveData(EEG, PreProcConstants.outputs{7});

