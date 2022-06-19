# Predictive-Modelling---Machine-Learning

## Machine Learning Classification Task - Predict clients likey to donate to charity 

### Goal & Objective
Goal was to predict if a particular individual should be solicited for donation or not. 
For achieving this, combined the results of classification, likelihood of donaiton and regression model, predicted amount of donation. By combining these two predictions, we obtained the expected revenue from each individual. Since, every solicitation costs 2 Euro, therefore if the expected predicted revenue exceeds this figure of 2 Euro, we will recommend the charity to solicit that individual, as the expected profit is positive. Performance of the model was measured by calculating the overall financial performance of the campaign, that is, (total actual donation amount - total cost of solicitation from our recommendation).

### Methodology - 
- **Discrete Model for Likelihood of Donation**: Important features for this model were 'Recency' which was the difference b/w the today's date and most recent donation date, 'Frequency' which is the number of times that individual donated, 'Channel' used for making the donation like Cash, Cheque, Online, Card, etc, and 'Gender' of the individuals. Also, multiplied the recency and frequency to create a new feature and took log of recency and frequency to normalize them. Applied the simple Logistic Regression model, to get the probability of predictions.

- **Continous Model to Predict Donation Amount**: Important features for this model were 'Average Donation Amount', 'Maximum Donation Amount', 'Minimum Donation Amount' and 'Gender' of the individual. Took the log of these variables, to make their distribution normal. Applied the simple linear regression, to predict the log of donation amount and then took exponential for the final output.

- Apply both the models on test dataset, and multiply these predictions (% and Euro) to obtain the expected revenue if solicited.
- If the expected revenue is superior to 2 Euro, solicit, otherwise do not.

### Results - 
The final model achieved the net donation of 210k Euro in test dataset.
