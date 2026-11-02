# La Liga Match Predictor

Predicting the result of La Liga matches (home win, draw or away win) with a decision tree in R, and comparing it with a simple baseline and the bookmakers.

## Goal
Build a classification model that beats a simple baseline: always predicting a home win.

## Data
- Match results from [football-data.co.uk](https://www.football-data.co.uk)
- Seasons 2021/22 to 2025/26, plus 2026/27 up to October: **1,999 matches**
- Results in the data: **45.7%** home wins, **26.2%** draws, **28.1%** away wins

## Method
1. **Load and clean** all seasons into one table
2. **Exploratory data analysis**: result distribution and goals per match for home and away teams
3. **Features**: for both teams, the average over their **last 5 matches before the game**:
   - points per match
   - goals scored
   - goals conceded

   Only information known *before* kick-off is used. Stats from the same match (goals, shots) would be **data leakage**.
4. **Time-based train/test split**: train on 2021/22 to 2024/25, test on 2025/26 and 2026/27. The model always predicts the future from the past.
5. **Decision tree** (`rpart`), with `maxdepth`, `minsplit` and `cp` tuned by **5-fold cross-validation** on the training data (36 combinations)
6. **Evaluation** on the test set against two benchmarks:
   - **Baseline**: always predict a home win
   - **Bookmaker**: Bet365's favourite (the result with the lowest odds)

## Results

| Method | Accuracy on test set |
|---|---|
| Baseline (always home win) | XX% |
| Decision tree | XX% |
| Bookmaker (Bet365 favourite) | XX% |

The decision tree picked the same result as the bookmaker in **XX%** of the test matches.

![Model vs bookmaker vs baseline](plots/model_vs_bookmaker.png)

## Conclusion
The decision tree **did not beat the home-win baseline**. Form over the last 5 matches carries too little information to predict football results. The model almost never predicts draws, and when it predicts an away win it is wrong more often than the simple "home team wins" rule.

Bookmakers set the bar for what is possible. Football has a lot of randomness: if anyone could predict results with 80–90% accuracy, bookmakers would go out of business.

## Limitations
- **Opponent strength is ignored**: beating the top team counts the same as beating the bottom team
- **5 matches is a noisy measure** of how good a team is; one bad week makes a top team look weak
- **Form carries over the summer break**, even though squads change between seasons
- **Draws are very hard to predict**
- **Small dataset and a single tree**: about 1,900 matches, and one decision tree can change a lot with small changes in the data
- **Random cross-validation folds** mix time within the training data; a time-based cross-validation would be stricter

## What I learned
- Why **data leakage** makes a model look great in testing but fail in reality
- Why football data must be **split by time**, not randomly
- The difference between **cross-validation** (choosing hyperparameters) and the **test set** (final evaluation, used once)
- Why a **baseline** is needed: a model is only useful if it beats the simplest possible rule
- Combining tables with `merge()`, the same idea as a JOIN in SQL

## Next steps
- Add a season-long measure of team strength (e.g. points per match this season or an Elo rating)
- Separate home form and away form
- Try a **random forest** (many trees instead of one)
- Use time-based cross-validation

## How to run
1. Install R and the packages: `ggplot2`, `rpart`, `rpart.plot`
2. Put the season CSV files from football-data.co.uk in the `data` folder
3. Set the working directory to the `data` folder and run `RScript.R`
