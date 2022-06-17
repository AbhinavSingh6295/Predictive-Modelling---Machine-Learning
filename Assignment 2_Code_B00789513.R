library(RODBC)

#Connect R with Mysql using odbc 
db = odbcConnect("my_data_source", uid="root", pwd="root")
sqlQuery(db, "USE ma_charity_full")

#Dataset with calibration 1 to train the probability and amount model
query = "select b.contact_id, 
		            coalesce((DATEDIFF(20180626, MAX(a.act_date)) / 365),0) as 'recency', count(a.amount) as 'frequency', coalesce(avg(a.amount),0) as 'avgamount', 
		            coalesce(max(a.amount),0) as 'maxamount',coalesce(min(a.amount),0) as 'minamount', coalesce((datediff(20180626, MIN(a.act_date)) / 365),0) as 'firstdonation',
                coalesce(c.channel_id,0) as 'channelid',
                coalesce(d.gender, 0) as 'gender',
                b.donation as 'loyal', b.amount as 'targetamount'
        from  assignment2 b
        left join acts a on b.contact_id = a.contact_id
        left join (
        			select b.contact_id, b.channel_id from (
        			select * , row_number() over (partition by a.contact_id order by a.counta desc) as 'rowocc' 
        			from (select contact_id, channel_id, count(*) as 'counta'
        			from acts
        			group by contact_id, channel_id) a) b
        			where b.rowocc = 1) c on b.contact_id = c.contact_id
        left join (
        select *, 
        CASE 
        	when prefix_id = 'MR' then 'M'
            when prefix_id = 'MME' then 'F'
            when prefix_id = 'MLLE' then 'F'
            when prefix_id = 'MMME' then 'M'
            else 0
        end as 'gender'
        from contacts) d on b.contact_id = d.id
        where b.calibration = 1
        group by 1;"

data = sqlQuery(db, query)

print(head(data))


#One-hot encoding of Channelid and Gender features
library('fastDummies')
data = dummy_cols(data, select_columns = c('channelid','gender'))
print(head(data))

#Remove unnecessary columns form the data
rownames(data) = data$contact_id
data = data[ ,-1]
data = subset(data, select = -c(gender, gender_0, channelid, channelid_0 ))
print(head(data))

########################################### Probability Model ######################################


plot(x = data$recency, y = data$loyal)

# Logistic Regression Model
library(nnet)
prob.model = glm(formula = loyal ~ (recency * frequency) + log(recency+1) + log(frequency+1) + channelid_MA 
                      + channelid_WW + gender_F + gender_M, data= data, family='binomial')
classPredicted = predict(prob.model, newdata = data, "response")
print(head(classPredicted))

#AUC score to check models performance
library(pROC)
auc(data$loyal, classPredicted)


#################################### Donation Amount Model #####################################################

#Select the row where target amount is not null
z = which(!is.na(data$targetamount))
print(head(data[z,]))
print(nrow(data[z,]))

#Evaluation function for amount model
eval_metrics = function(model, df, predictions, target){
  resids = df[,target] - predictions
  resids2 = resids**2
  N = length(predictions)
  r2 = as.character(round(summary(model)$r.squared, 2))
  adj_r2 = as.character(round(summary(model)$adj.r.squared, 2))
  print("Adjusted R-squared")
  print(adj_r2) #Adjusted R-squared
  print("RMSE")
  print(as.character(round(sqrt(sum(resids2)/N), 2))) #RMSE
}

plot(x = data[z,]$gender_F, y = log(data[z,]$target))

#linear regression; Results - AdjR=0.72, RMSE=88.95
amount.model = lm(formula = log(targetamount) ~ log(avgamount) + log(maxamount) + log(minamount) +
                  log(avgamount)*log(maxamount) + gender_F
                  ,data = data[z,])
predictions = exp(predict(object=amount.model, newdata=data[z,]))
eval_metrics(amount.model, data[z,], predictions, "targetamount")


# Model Statistics
summary(amount.model)


#################################### Prediction data from database #######################################

#New dataset with calibration 0 to make predicitons on
query = "select b.contact_id, 
		            coalesce((DATEDIFF(20180626, MAX(a.act_date)) / 365),0) as 'recency', count(a.amount) as 'frequency', coalesce(avg(a.amount),0) as 'avgamount', 
		            coalesce(max(a.amount),0) as 'maxamount',coalesce(min(a.amount),0) as 'minamount', coalesce((datediff(20180626, MIN(a.act_date)) / 365),0) as 'firstdonation',
                coalesce(c.channel_id,0) as 'channelid',
                coalesce(d.gender, 0) as 'gender'
        from  assignment2 b
        left join acts a on b.contact_id = a.contact_id
        left join (
        			select b.contact_id, b.channel_id from (
        			select * , row_number() over (partition by a.contact_id order by a.counta desc) as 'rowocc' 
        			from (select contact_id, channel_id, count(*) as 'counta'
        			from acts
        			group by contact_id, channel_id) a) b
        			where b.rowocc = 1) c on b.contact_id = c.contact_id
        left join (
        select *, 
        CASE 
        	when prefix_id = 'MR' then 'M'
            when prefix_id = 'MME' then 'F'
            when prefix_id = 'MLLE' then 'F'
            when prefix_id = 'MMME' then 'M'
            else 0
        end as 'gender'
        from contacts) d on b.contact_id = d.id
        where b.calibration = 0
        group by 1;"
newdata = sqlQuery(db, query)
print(head(newdata))

#Creat dummy features in newdata 
newdata = dummy_cols(newdata, select_columns = c('channelid','gender'))
print(head(newdata))

#Close the odbc connection
odbcClose(db)



#Predictions

#New dataframe for storing the ouput
out = data.frame(contact_id = newdata$contact_id)

#Predictions from probability model
out$probs = predict(object = prob.model, newdata = newdata, type="response")

#Predicitons from amount model
out$amount = exp(predict(object = amount.model, newdata = newdata))

#Final score by multiplying the result of probability and amount model
out$score = out$probs * out$amount

print(head(out))

#Count of contact id with score greater than 2
z = which(out$score > 2)
print(length(z))
print(nrow(out))

#Indicator for whether to send solicitations or not.
out$IsSolicit[out$score > 2] = 1
out$IsSolicit[out$score < 2] = 0

#Final text output with required columns for submission
final = out[ ,-2:-4]

write.table(final, file = 'FinalOutput_V3.txt', sep="\t", row.names = FALSE, col.names = FALSE )
