select * from credit_card_transcations;

--1.write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

with city as (
select city, sum(cast (amount as bigint)) as city_total
from credit_card_transcations
group by city ),
total as (
select sum(cast (amount as bigint)) as total from credit_card_transcations
)
select top 5 city,c.city_total,t.total ,city_total*100.0/total  as perc
from city c cross join total t
order by perc desc;


--2.write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type,DATEPART(year,transaction_date) yr,DATEPART(month,transaction_date) mm,sum(amount) as my_spend
from credit_card_transcations
group by card_type, DATEPART(year,transaction_date), DATEPART(month,transaction_date) )
select * from 
(select *,
row_number() over (partition by card_type order by my_spend desc) as rn 
from cte) a
where rn=1;


--3.write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte1 as (
select *, sum(amount) over (partition by card_type order by transaction_date,transaction_id) as total
from credit_card_transcations ),
cte2 as (
select *, rank() over (partition by card_type order by total) as rn
from cte1
where total >= 1000000)
select * 
from cte2
where rn =1;


--4.write a query to find city which has lowest percentage spend for gold card type

with city_spend as (
select city, sum(amount) as city_total
from credit_card_transcations
where card_type = 'Gold'
group by city ),
overall_sum as (
select city, sum(cast (amount as bigint)) as total  
from credit_card_transcations
group by city
)
select top 5 ac.city, city_total,total,cast(c.city_total*100.0/s.total as decimal(5,2)) as perc
from city_spend c inner join overall_sum s
on c.city = s.city
order by perc asc;


--5.write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as (
select city,exp_type,sum(amount) city_exp_spend
from credit_card_transcations
group by city,exp_type
--order by city,city_exp_spend 
),
cte2 as (
select *,
ROW_NUMBER() over (partition by city order by city_exp_spend) as rn,
ROW_NUMBER() over (partition by city order by city_exp_spend desc) as rnd
from cte) 
select city, 
max(case when rn = 1 then exp_type end) as least_exp,
max(case when rnd = 1 then exp_type end) as high_exp
from cte2
where rn =1 or rnd =1 
group by city;


--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type, sum(amount) as total,
sum(case when gender = 'F' then amount else 0 end) as fem_exp,
sum(case when gender = 'F' then amount else 0 end)*1.0/sum(amount)*100 as perc
from credit_card_transcations
group by exp_type ;


--7. which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type,DATEPART(year,transaction_date) yr, datepart(month,transaction_date) mm, sum(amount) all_expenses
from credit_card_transcations
group by card_type,exp_type,DATEPART(year,transaction_date), datepart(month,transaction_date) ),

cte2 as (
select * ,lag(all_expenses,1) over (partition by card_type,exp_type order by yr,mm) as prev_month_exp
from cte )

select * ,(all_expenses - prev_month_exp) as mom_growth
from (
select *
from cte2) a
where prev_month_exp is not null and yr =2014 and mm = 1
order by mom_growth desc;



--8. during weekends which city has highest total spend to total no of transcations ratio 

select city,sum(amount) *1.0/count(transaction_id) as trans_ratio
from credit_card_transcations
where datepart(WEEKDAY,transaction_date) in (1,7)
group by city
order by trans_ratio desc;


--9.which city took least number of days to reach its 500th transaction after the first transaction in that city
 
with cte as (
select *, 
ROW_NUMBER() over (partition by city order by transaction_date asc) as rn
from credit_card_transcations )
select city, min(transaction_date) as first_tran,max(transaction_date) as last_tran,
DATEDIFF(day,min(transaction_date),max(transaction_date)) as day_diff
from cte 
where rn in (1,500)
group by city
having count(*) = 2
order by day_diff asc;

