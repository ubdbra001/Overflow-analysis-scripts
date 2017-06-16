
dataDir = '/Volumes/Samsung/EEG Data/DCD/Hana/Behavioural';
cd(dataDir)

outputFName  = 'MeanFreq.csv';
outputHeader = 'ID, Group, Slow, Medium, Fast\n';

files = dir('P*.mat');              % Find all data files

testOutput = nan(length(files),3);  % Preallocate output variable

fid = fopen(outputFName, 'w');      % Create and open output data file
fprintf(fid, outputHeader);         % Write header to file

for file_n = 1:length(files)        % Loop through each file
    
    fileName = files(file_n).name;  % Generate filename
    [~, fileID, ~] = fileparts(fileName); % Generate ID
    
    load(fileName)                  % Load file
    
    OverflowBehavData.(fileID) = results; % Place in grouped fine (currently this is not strictly needed)
    clear results                   % Clear loaded file
    
    testOutput(file_n,:) = mean(cellfun('length', OverflowBehavData.(fileID))/5); % Calculate mean tapping frequency
    
    condition = strsplit(fileID, '_');  % Get condition
    
    fprintf(fid,'P%0d,%s,%.3f,%.3f,%.3f\n',file_n, condition{2},testOutput(1,:)); % Write output to CSV
    
end

fclose(fid);
