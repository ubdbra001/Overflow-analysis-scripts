
dataDir = '/Volumes/Samsung/EEG Data/DCD/Hana/Behavioural';
cd(dataDir)

outputFName  = 'MeanFreq.csv';
outputHeader = 'ID, Group, Slow, Medium, Fast\n';

files = dir('P*.mat');

testOutput = nan(length(files),3);

fid = fopen(outputFName, 'w');                     % Create and open output data file
fprintf(fid, outputHeader);

for file_n = 1:length(files)
    
    fileName = files(file_n).name;
    [~, fileID, ~] = fileparts(fileName);
    
    load(fileName)
    
    OverflowBehavData.(fileID) = results;
    clear results
    
    testOutput(file_n,:) = mean(cellfun('length', OverflowBehavData.(fileID))/5);
    
    a = strsplit(fileID, '_');
    
    fprintf(fid,'P%0d,%s,%.3f,%.3f,%.3f\n',file_n, a{2},testOutput(1,:));
    
end

fclose(fid);
