USE ma_charity_full;

select * from ma_charity_full.assignment2;
select count(distinct contact_id) from acts;

# Contact ID from Assignment2 table not present in the Acts table, how will we predict the information for these cases? For calibration = 1, its 22 & 
# for calibration = 0, its 25

select a.contact_id as 'ID1', b.contact_id  
from assignment2 a
left join acts b
on a.contact_id = b.contact_id
where b.contact_id is NULL and a.calibration = 0
group by a.contact_id;

#Count of contact ID's in Acts Data is 256,474.
select * #count(distinct contact_id)
from acts
where contact_id = 985824;

# 22 Contact Id's with Calibration = 1 from assignment2 table are not present in acts table. So, we have 61,906 ID's after left join. Out of these 61,906 IDs,
# 59,283 are with act_type_id = DO
# 25 Contact Id's with Calibration = 0 from assignment2 table are not present in acts table. So, we have 61,719 ID's after left join. Out of these 61,719 IDs,
# 58,982 are with act_type_id = DO. Some contact ID's are both DO and PA, 

select count(*) from (
select distinct(a.contact_id)
from assignment2 a
left join acts b on a.contact_id = b.contact_id
where a.calibration = 1 # and a.act_type_id = "DO"
group by a.contact_id )a;

#Train Data for the model. Only 6429 rows has data for target amount. 

select b.contact_id, 
		coalesce((DATEDIFF(20180626, MAX(a.act_date)) / 365),0) as 'recency', count(a.amount) as 'frequency', coalesce(avg(a.amount),0) as 'avgamount', 
		coalesce(max(a.amount),0) as 'maxamount', coalesce((datediff(20180626, MIN(a.act_date)) / 365),0) as 'firstdonation',
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
	when prefix_id = "MR" then "M"
    when prefix_id = "MME" then "F"
    when prefix_id = "MLLE" then "F"
    when prefix_id = "MMME" then "M"
    else 0
end as 'gender'
from contacts) d on b.contact_id = d.id
where b.calibration = 1
group by 1;





#Prediction Data for the model
select b.contact_id, 
		coalesce((DATEDIFF(20180626, MAX(a.act_date)) / 365),0) as 'recency', count(a.amount) as 'frequency', coalesce(avg(a.amount),0) as 'avgamount', 
		coalesce(max(a.amount),0) as 'maxamount', coalesce((datediff(20180626, MIN(a.act_date)) / 365),0) as 'firstdonation',
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
	when prefix_id = "MR" then "M"
    when prefix_id = "MME" then "F"
    when prefix_id = "MLLE" then "F"
    when prefix_id = "MMME" then "M"
    else 0
end as 'gender'
from contacts) d on b.contact_id = d.id
where b.calibration = 0
group by 1;


select a.contact_id
from (
select distinct(a.contact_id)
from acts a
left join assignment2 b on a.contact_id = b.contact_id
where b.calibration = 0  and a.act_type_id = "PA" ) a
where not exists (select * from (
select distinct(a.contact_id)
from acts a
left join assignment2 b on a.contact_id = b.contact_id
where b.calibration = 0  and a.act_type_id = "DO") b
where a.contact_id = b.contact_id);


















