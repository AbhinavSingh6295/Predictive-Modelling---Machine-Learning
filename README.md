# Predictive-Modelling---Machine-Learning

## Machine Learning Classification Task - Predict Clients likey to donate to Charity 

### Goal & Objective
Goal was to predict if a particular individual should be solicited or not. 
For achieving this, first, we predicted the likelihood of donation of individual to make donation to the charity and then, we predicted the amount of money they are likely to give. 
By combining these two predictions, we obtained the expected revenue from each individual. Since, every solicitation costs 2 Euro, therefore if the expected predicted revenue exceeds this figure of 2 Euro, we will recommend the charity to solicit that individual, as the expected profit is positive. 
If it is below 2 Euro, we will recommend the charity to not to solicit that individual, since on an average you can expect a loss. 
Performance of the model was measured by calculating the overall financial performance of the campaign, that is, (total actual donation amount - total cost of solicitation after our recommendation).

### Methodology - 
- **Discrete Model for Likelihood of Donation**: Important features for this model were 'Recency' which was the difference b/w the today's date and most recent donation date, 'Frequency' which is the number of times that individual donated, 'Channel' used for making the donation like Cash, Cheque, Online, Card, etc, 'Gender' of the individual. In features modification step, we multiplied the recency and frequency, took log of recency and frequency.
Applied the simple Logistic Regression model, to get the probability of predictions.

- **Continous Model to Predict Donation Amount**: Important features for this model were Average Donation Amount, Maximum Donation Amount, Minimum Donation Amount and Gender of the individual. 
In features modification step, we took the log of these amount, to make their distribution normal. 
Applied simple linear regression, to predict the log of donation amount and then took exponential for the final output.

- Apply both the models on prediction data, and multiply these predictions (% and Euro) to obtain the expected revenue if solicited.
- If the expected revenue is superior to 2 Euro, solicit, otherwise do not.

### Results - 
The final model achieved the net donation of 210k Euro in test dataset.




