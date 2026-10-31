# La Liga Match Predictor

Predicting the result of La Liga matches (home win, draw or away win) with decision trees in R.

## Goal
Build a classification model that beats a simple baseline: always predicting a home win.

## Data
Match results from 6 La Liga seasons, from [football-data.co.uk](https://www.football-data.co.uk).

## Method (planned)
1. Load and clean the data
2. Exploratory data analysis (EDA)
3. Create features from previous matches only (e.g. team form over the last 5 games) to avoid data leakage
4. Train a decision tree (`rpart`) and tune hyperparameters with 5-fold cross-validation
5. Evaluate on a held-out test set and compare with the baseline

## Status
🚧 In progress: data loading and cleaning done.
