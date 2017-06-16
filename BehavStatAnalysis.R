# Load dependencies
library(reshape2)
library(readr)
library(ez)

# Import data as dataframe
MeanFreq = as.data.frame(read_csv("/Volumes/Samsung/EEG Data/DCD/Hana/Behavioural/MeanFreq.csv"))

# Change to format suitable for ANOVA
longFreq = melt(MeanFreq)

# Give names to each variable
names(longFreq) = c("ID", "Group", "Speed", "Value")

# Turn Speed variable into a factor
longFreq$Speed = factor(longFreq$Speed, labels = c("Slow", "Medium", "Fast"))

# Reorder by Participant ID
longFreq = longFreq[order(longFreq$ID),]

# Grnerate ANOVA model
freqModel<-ezANOVA(data = longFreq, dv = .(Value), wid = .(ID), within = .(Speed), between = .(Group), detailed = TRUE, type = 3)
