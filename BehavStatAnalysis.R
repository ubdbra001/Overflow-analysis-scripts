library(reshape2)
library(readr)
library(ez)

MeanFreq = as.data.frame(read_csv("/Volumes/Samsung/EEG Data/DCD/Hana/Behavioural/MeanFreq.csv"))

longFreq = melt(MeanFreq)
names(longFreq) = c("ID", "Group", "Speed", "Value")

longFreq$Speed = factor(longFreq$Speed, labels = c("Slow", "Medium", "Fast"))
longFreq = longFreq[order(longFreq$ID),]

freqModel<-ezANOVA(data = longFreq, dv = .(Value), wid = .(ID), within = .(Speed), between = .(Group), detailed = TRUE, type = 3)
