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

ggplot(data = matches) + aes(x = FTR, fill = FTR) +
  geom_bar(color = "black") +
  labs(x = "Result", y = "Number of matches",
       title = "La Liga results (6 seasons)", fill = "Result")

#524= draws, 562= awaywins, 913= homewins
#A              D               H 
#0.2811406      0.2621311       0.4567284 


boxplot(matches$FTHG, matches$FTAG,
        names = c("Home", "Away"), main = "Goals per match")
