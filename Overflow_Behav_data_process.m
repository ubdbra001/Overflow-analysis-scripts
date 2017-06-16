
dataDir = '/Volumes/Samsung/EEG Data/DCD/Hana/Behavioural';
cd(dataDir)

files = dir('P*.mat');

testOutput = nan(length(files),3);

for file_n = 1:length(files)
    
    fileName = files(file_n).name;
    [~, fileID, ~] = fileparts(fileName);
    
    load(fileName)
    
    OverflowBehavData.(fileID) = results;
    clear results
    
    testOutput(file_n,:) = mean(cellfun('length', OverflowBehavData.(fileID))/5);
    
end
