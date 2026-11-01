rm(list = ls())
setwd("C:/Users/mahdm/Desktop/SpainFootballGamePredictor/data")

files = list.files(pattern = "SP1")
cols = c("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR", "HS", "AS", "HST", "AST")

matches = data.frame()
for (f in files) {
  season = read.csv(f, header = TRUE, sep = ",", stringsAsFactors = FALSE)
  matches = rbind(matches, season[, cols])
}

#preprocessing
matches = matches[!is.na(matches$FTR) & matches$FTR != "", ] #make sure ftr is not null or empty
matches$Date = as.Date(matches$Date, format = "%d/%m/%Y")
matches$FTR = factor(matches$FTR)
matches = matches[order(matches$Date), ]

#Barplot over the FTR to see the Homewins, draw, and Awaywins probabilities
library("ggplot2")
barplot(table(matches$FTR),
        main = "La Liga results",
        name.arg = c("Away wins", "Draw", "Home wins"))

ggplot(data=matches) + aes(x=FTR, fill) + 
  geom_bar(color = "black", position = "fill") +
  labs(x = "CKD status", y = "Proportion", title = "Relationship between CKD and Anemia", fill = "Anemia")
