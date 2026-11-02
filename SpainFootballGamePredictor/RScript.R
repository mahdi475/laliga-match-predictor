rm(list = ls())
setwd("C:/Users/mahdm/Desktop/SpainFootballGamePredictor/data")

# ============================================================
# 1. LOAD DATA (6 seasons)
# ============================================================
files = list.files(pattern = "SP1")
cols = c("Date", "HomeTeam", "AwayTeam", "FTHG", "FTAG", "FTR", "HS", "AS", "HST", "AST")

matches = data.frame()
for (f in files) {
  season = read.csv(f, header = TRUE, sep = ",", stringsAsFactors = FALSE)
  matches = rbind(matches, season[, cols])
}

# ============================================================
# 2. PREPROCESSING
# ============================================================
matches = matches[!is.na(matches$FTR) & matches$FTR != "", ] # make sure FTR is not empty
matches$Date = as.Date(matches$Date, format = "%d/%m/%Y")
matches$FTR = factor(matches$FTR)
matches = matches[order(matches$Date), ]

# ============================================================
# 3. EDA
# ============================================================
library("ggplot2")

# Barplot over FTR to see home wins, draws and away wins
ggplot(data = matches) + aes(x = FTR, fill = FTR) +
  geom_bar(color = "black") +
  labs(x = "Result", y = "Number of matches",
       title = "La Liga results (6 seasons)", fill = "Result")

# 524 = draws, 562 = away wins, 913 = home wins
# A          D          H
# 0.2811406  0.2621311  0.4567284

boxplot(matches$FTHG, matches$FTAG,
        names = c("Home", "Away"), main = "Goals per match")

# ============================================================
# 4. FEATURES: team form from the LAST 5 MATCHES (before the match)
# ============================================================
# We can only use information we know BEFORE the match starts.
# Using goals or shots from the same match would be data leakage.

# One row per team per match (every match = 2 rows: home team + away team)
home_games = data.frame(Date = matches$Date, Team = matches$HomeTeam,
                        GoalsFor = matches$FTHG, GoalsAgainst = matches$FTAG,
                        Points = ifelse(matches$FTR == "H", 3, ifelse(matches$FTR == "D", 1, 0)))
away_games = data.frame(Date = matches$Date, Team = matches$AwayTeam,
                        GoalsFor = matches$FTAG, GoalsAgainst = matches$FTHG,
                        Points = ifelse(matches$FTR == "A", 3, ifelse(matches$FTR == "D", 1, 0)))
team_games = rbind(home_games, away_games)
team_games = team_games[order(team_games$Date), ]

# Average points, goals scored and goals conceded in a team's last 5 matches before a date
get_form = function(team, date) {
  past = team_games[team_games$Team == team & team_games$Date < date, ]
  if (nrow(past) < 5) {
    return(c(NA, NA, NA)) # not enough history (e.g. the first matches in the data)
  }
  last5 = tail(past, 5)
  return(c(mean(last5$Points), mean(last5$GoalsFor), mean(last5$GoalsAgainst)))
}

# Empty columns that we fill in the loop
matches$HomePoints5 = NA
matches$HomeGoalsFor5 = NA
matches$HomeGoalsAgainst5 = NA
matches$AwayPoints5 = NA
matches$AwayGoalsFor5 = NA
matches$AwayGoalsAgainst5 = NA

for (i in 1:nrow(matches)) {
  home_form = get_form(matches$HomeTeam[i], matches$Date[i])
  away_form = get_form(matches$AwayTeam[i], matches$Date[i])
  
  matches$HomePoints5[i] = home_form[1]
  matches$HomeGoalsFor5[i] = home_form[2]
  matches$HomeGoalsAgainst5[i] = home_form[3]
  matches$AwayPoints5[i] = away_form[1]
  matches$AwayGoalsFor5[i] = away_form[2]
  matches$AwayGoalsAgainst5[i] = away_form[3]
}

# Keep only the result + the 6 features, and remove rows without enough history
features = c("HomePoints5", "HomeGoalsFor5", "HomeGoalsAgainst5",
             "AwayPoints5", "AwayGoalsFor5", "AwayGoalsAgainst5")
model_data = matches[, c("Date", "FTR", features)] # prepare a good data to prevent DATA LEAKAGE
model_data = na.omit(model_data) # delete rows with NA

# ============================================================
# 5. TRAIN / TEST SPLIT (by time)
# ============================================================
# Train on older seasons, test on the newest ones -> we predict the future from the past
train = model_data[model_data$Date < as.Date("2025-07-01"), ]
test = model_data[model_data$Date >= as.Date("2025-07-01"), ]
train$Date = NULL
test$Date = NULL

nrow(train)
nrow(test)

# ============================================================
# 6. HYPERPARAMETER TUNING WITH 5-FOLD CROSS-VALIDATION
# ============================================================
library("rpart")

set.seed(42)
folds = sample(rep(1:5, length.out = nrow(train))) # gives every training row a fold number 1-5

# All combinations of hyperparameters we want to test
grid = expand.grid(maxdepth = c(2, 3, 4, 5),
                   minsplit = c(20, 50, 100),
                   cp = c(0.001, 0.005, 0.01))
grid$accuracy = NA

for (g in 1:nrow(grid)) {
  fold_accuracy = c()
  for (k in 1:5) {
    fold_train = train[folds != k, ] # 4 folds for training
    fold_test = train[folds == k, ]  # 1 fold for testing
    
    tree = rpart(FTR ~ ., data = fold_train, method = "class",
                 control = rpart.control(maxdepth = grid$maxdepth[g],
                                         minsplit = grid$minsplit[g],
                                         cp = grid$cp[g]))
    pred = predict(tree, fold_test, type = "class")
    fold_accuracy = c(fold_accuracy, mean(pred == fold_test$FTR))
  }
  grid$accuracy[g] = mean(fold_accuracy) # average accuracy over the 5 folds
}

best = grid[which.max(grid$accuracy), ]
best

# ============================================================
# 7. FINAL MODEL + EVALUATION ON THE TEST SET
# ============================================================
final_tree = rpart(FTR ~ ., data = train, method = "class",
                   control = rpart.control(maxdepth = best$maxdepth,
                                           minsplit = best$minsplit,
                                           cp = best$cp))

test_pred = predict(final_tree, test, type = "class")

model_accuracy = mean(test_pred == test$FTR)
baseline_accuracy = mean(test$FTR == "H") # always guessing "home win"

model_accuracy
baseline_accuracy

# Confusion matrix: which results does the model get wrong?
table(Predicted = test_pred, Actual = test$FTR)

# Plot the tree
library("rpart.plot")
rpart.plot(final_tree, main = "Decision tree for La Liga results")

# Model vs baseline
results = data.frame(Model = c("Baseline (always home win)", "Decision tree"),
                     Accuracy = c(baseline_accuracy, model_accuracy))
ggplot(data = results) + aes(x = Model, y = Accuracy, fill = Model) +
  geom_col(color = "black") +
  labs(x = "", y = "Accuracy on test set", title = "Decision tree vs baseline")


# ============================================================
# 8. MODEL vs BOOKMAKER vs REAL RESULT
# ============================================================
# Load the bookmaker odds (only for comparison, NOT used by the model)
odds = data.frame()
for (f in files) {
  season = read.csv(f, header = TRUE, sep = ",", stringsAsFactors = FALSE)
  odds = rbind(odds, season[, c("Date", "HomeTeam", "AwayTeam", "B365H", "B365D", "B365A")])
}
odds$Date = as.Date(odds$Date, format = "%d/%m/%Y")

# Test matches + our prediction
check = matches[rownames(test), c("Date", "HomeTeam", "AwayTeam", "FTR")]
check$Model = test_pred

# Add the odds to every test match (like a JOIN in SQL)
check = merge(check, odds, by = c("Date", "HomeTeam", "AwayTeam"))
check = na.omit(check)

# Bookmaker's pick = the result with the lowest odds
check$Bookie = c("H", "D", "A")[apply(check[, c("B365H", "B365D", "B365A")], 1, which.min)]

check$ModelCorrect = check$FTR == check$Model
check$BookieCorrect = check$FTR == check$Bookie
View(check)

mean(check$ModelCorrect)            # our accuracy
mean(check$BookieCorrect)           # bookmaker accuracy
mean(check$Model == check$Bookie)   # how often we pick the same as the bookmaker

# Model vs bookmaker vs baseline
results = data.frame(Method = c("Baseline (always H)", "Decision tree", "Bookmaker"),
                     Accuracy = c(mean(check$FTR == "H"),
                                  mean(check$ModelCorrect),
                                  mean(check$BookieCorrect)))

ggplot(data = results) + aes(x = Method, y = Accuracy, fill = Method) +
  geom_col(color = "black") +
  geom_text(aes(label = paste0(round(Accuracy * 100, 1), "%")), vjust = -0.5) +
  ylim(0, 1) +
  labs(x = "", y = "Accuracy on test set",
       title = "Decision tree vs bookmaker vs baseline") +
  theme(legend.position = "none")
