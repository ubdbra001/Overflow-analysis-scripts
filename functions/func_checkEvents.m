function [EEG, error] = func_checkEvents(EEG)

markers_in_file = unique([EEG.event.type]);

n = 0;
error = 0;

for marker = markers_in_file
   
    if sum([EEG.event.type]==marker) < 60 
        continue
    else
        n = n+1;
        [EEG.event([EEG.event.type]==marker).type] = deal(Overflow_preproccessing_constants.markers(n));
    end
end

if n ~= 3     % Show warning as the events are screwed up!
    warningMes = 'Warning: unexpected number of events found in this file!';
    func_warning(warningMes);
    error = 1;
end