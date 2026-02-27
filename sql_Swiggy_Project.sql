create table Swiggy_Data(
 State varchar(150),
 City varchar(150),
 Order_Date date,
 Restaurant_Name varchar(150),
 Location varchar(150),
 Category varchar(150),
 Dish_Name varchar(200),
 Price_INR float,
 Rating float,
 Rating_Count smallint
 )

copy Swiggy_Data from 'D:\alma_quiz\PROJECTS\Swiggy_Data.csv' delimiter ',' csv header

select * from Swiggy_Data

--Data Validation & Cleaning
--Null check

select 
sum(case when State is null then 1 else 0 end) as null_state,
sum(case when City is null then 1 else 0 end) as null_city,
sum(case when Order_Date is null then 1 else 0 end) as null_order_date,
sum(case when Restaurant_Name is null then 1 else 0 end) as null_restaurant,
sum(case when Location is null then 1 else 0 end) as null_location,
sum(case when Category is null then 1 else 0 end) as null_category,
sum(case when Dish_Name is null then 1 else 0 end) as null_dish,
sum(case when Price_INR is null then 1 else 0 end) as null_price,
sum(case when Rating  is null then 1 else 0 end) as null_rating,
sum(case when Rating_Count is null then 1 else 0 end) as null_rating_count
from Swiggy_Data

--Blank Or Empty Strings

select * from Swiggy_Data
where State='' or City='' or Restaurant_Name='' or Location='' or Category=''
or Dish_Name='' ;

--Duplicate Detection

select State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count, count(*) as CNT
from Swiggy_Data
group by 
State,City,Order_Date,Restaurant_Name,Location,Category,
Dish_Name,Price_INR,Rating,Rating_Count
having count(*)>1

--Delete Duplication
--Not supported by postgresql
WITH New_Table AS(
select *,row_number() over(
   partition by state,City,Order_Date,Restaurant_Name,Location,Category,
	Dish_Name,Price_INR,Rating, Rating_Count
order by (select null)
)as rn
from Swiggy_Data 
)
DELETE FROM New_Table WHERE rn>1

--For postgresql
DELETE FROM Swiggy_Data s
USING (
    SELECT ctid
    FROM (
        SELECT ctid,
               row_number() OVER (
                   PARTITION BY state, City, Order_Date, Restaurant_Name, Location, Category,
                                Dish_Name, Price_INR, Rating, Rating_Count
                   ORDER BY (SELECT NULL)
               ) AS rn
        FROM Swiggy_Data
    ) t
    WHERE rn > 1
) d
WHERE s.ctid = d.ctid;

--CREATING SCHEMA
--DIMENSION TABLES
--DATE TABLE

create table dim_date(
Date_id serial primary key,
Full_Date date,
Year int,
Month int,
Month_Name varchar(20),
Quarter int, 
Day int, 
Week int
)

select * from dim_date

--dim_location
create table dim_location(
Location_id serial primary key,
State varchar(100),
City varchar(100),
Location varchar(200)
)

select * from dim_location


--dim Restaurant

create table dim_restaurant(
Restaurant_id serial primary key,
Restaurant_Name varchar(200)
)

select * from dim_restaurant

--dim Category

create table dim_category(
Category_id serial primary key,
Category varchar(200)
)

select * from dim_category

--dim dish

create table dim_dish(
Dish_id serial primary key,
Dish_Name varchar(200)
)

select * from dim_dish

select * from Swiggy_Data

--FACT TABLE

create table fact_swiggy_orders(
Order_id serial primary key,

Date_id serial,
Price_INR decimal(10,2),
Rating decimal(4,2),
Rating_Count int,

Location_id serial,
Restaurant_id serial,
Category_id serial,
Dish_id serial,

foreign key (Date_id) references dim_date(Date_id),
foreign key (Location_id) references dim_location(Location_id),
foreign key (Restaurant_id) references dim_Restaurant(Restaurant_id),
foreign key (Category_id) references dim_Category(Category_id),
foreign key (Dish_id) references dim_Dish(Dish_id)
)
 select * from fact_swiggy_orders

--INSERT DATA IN TABLES 
--DIM DATA

--Not Supported in Postgresql
insert into dim_date(Full_Date,Year,Month,Month_Name,Quarter,Day,Week)
select Distinct
    Order_Date,
	Year(Order_Date),
	Month(Order_Date),
	DateName(Month, Order_Date),
	datepart(Quarter,Order_Date),
	Day(Order_Date),
	datepart(Week,Order_Date)
from Swiggy_Data
where Order_Date is not null;
	
--FOR POSTGRESQL...
insert into dim_date(Full_Date, Year,Month,Month_Name,Quarter,Day,Week)
select distinct
    Order_Date,
	extract(Year from Order_Date)::int,
	extract(Month from Order_Date)::int,
	to_char(Order_Date,'Month'),
	extract(Quarter from Order_Date)::int,
	extract(Day from Order_Date)::int,
	extract(Week from Order_Date)::int
from Swiggy_Data
where Order_Date is not null;

select * from dim_date

--dim location
insert into dim_location(State,City,Location)
select distinct 
      State,
	  City,
	  Location
from Swiggy_Data;	  
	  
select * from dim_location

--dim Restaurant
insert into dim_restaurant(Restaurant_Name)
select distinct 
    Restaurant_Name
from Swiggy_Data	

select * from dim_restaurant

--dim Category
insert into dim_category(Category)
select distinct
      Category
from Swiggy_Data	  

select * from dim_category	  

--dim dish
insert into dim_dish(Dish_Name)
select distinct
     Dish_Name
from Swiggy_Data;	 

select * from dim_dish

--Fact Table

insert into fact_swiggy_orders
(
   Date_id,
   Price_INR,
   Rating,
   Rating_Count,
   Location_id,
   Restaurant_id,
   Category_id,
   Dish_id
)
select
    dd.Date_id,
	s.Price_INR,
	s.Rating,
	s.Rating_Count,

	dl.Location_id,
	dr.Restaurant_id,
	dc.Category_id,
	dsh.Dish_id
from Swiggy_Data s

join dim_date dd
  on dd.Full_Date = s.Order_Date

join dim_location dl
   on dl.State= s.State
   and dl.City= s.City
   and dl.Location= s.Location

join dim_restaurant dr 
   on dr.Restaurant_Name= s.Restaurant_Name

join dim_Category dc
   on dc.Category= s.Category

join dim_dish dsh
   on dsh.Dish_Name=s.Dish_Name;

select * from fact_swiggy_orders

--SEE DATA IN ALL TABLES
select * from fact_swiggy_orders f
join dim_date d on f.Date_id= d.Date_id
join dim_location l on f.Location_id= l.Location_id
join dim_restaurant r on f.Restaurant_id= r.Restaurant_id
join dim_category c on f.Category_id= c.Category_id
join dim_dish di on f.Dish_id= di.dish_id;

--KPI

--TOTAL OTDERS
select count(*) as Total_Orders
from fact_swiggy_orders

--TOTAL REVENUE(INR million)
select sum(Price_INR) as Total_Revenue
from fact_swiggy_orders

--Converting into (INR million)
select
format(sum(convert(float,Price_INR))/1000000,'N2' +'INR million')
as Total_Revenue
from fact_swiggy_orders

--for postgresql
SELECT 
    TO_CHAR(SUM(Price_INR::float) / 1000000, 'FM999999999.00') || ' INR million' AS Total_Revenue
FROM fact_swiggy_orders;

--AVERAGE DISH PRICE
select
   to_char(avg(Price_INR::float),'FM999999999.00') || ' INR'
   as Average_Dish_Price
from fact_swiggy_orders 

--AVERAGE RATING
select 
avg(Rating) as  Avg_Rating
from fact_swiggy_orders

--extra
select 
round(avg(Rating), 2) as  Avg_Rating
from fact_swiggy_orders

--Deep-Dive Buisness Analysis

--Monthly Order Trends
select
d.Year,
d.Month,
d.Month_Name,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.Date_id=d.Date_id
group by d.Year,
d.Month,
d.Month_Name
order by count(*) desc

-- Monthly Total Revenue Trends
select
d.Year,
d.Month,
d.Month_Name,
sum(Price_INR) as Total_Revenue
from fact_swiggy_orders f
join dim_date d on f.Date_id=d.Date_id
group by d.Year,
d.Month,
d.Month_Name
order by count(*) desc

--Quaterly Trend
select
d.Year,
d.Quarter,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.Date_id=d.Date_id
group by d.Year,
d.Quarter
order by count(*) desc

--Yearly Orders(Trend)
select
d.Year,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.Date_id=d.Date_id
group by d.Year
order by count(*) desc

--Orders by Day Of Week(Mon-Sun)
select 
   DateName(weekday, d.Full_Date) as day_name,
   count(*) as total_orders
from fact_swiggy_orders f
join dim_date d on f.Date_id=d.Date_id
group by DateName(weekday,d.Full_Date),datepart(weekay,d.Full_Date)
order by datepart(weekday, d.Full_Date);

--for postgresql
SELECT 
    TO_CHAR(d.Full_Date, 'Day') AS day_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d 
    ON f.Date_id = d.Date_id
GROUP BY 
    TO_CHAR(d.Full_Date, 'Day'),
    EXTRACT(DOW FROM d.Full_Date)
ORDER BY 
    EXTRACT(DOW FROM d.Full_Date);

--LOCATION BASED ANALYSIS

--Top 10 Cities By Order Volume
select 
l.City,
count(*) as Total_Orders 
from fact_swiggy_orders f
join dim_location l on l.Location_id=f.Location_id
group by l.City
order by count(*) desc
limit 10

--Sum Of Sales
select
l.City,
sum(f.Price_INR) as Total_Revenue
from fact_swiggy_orders f
join dim_location l on l.Location_id=f.Location_id
group by l.City
order by sum(f.Price_INR) desc
limit 10

--Revenue Contribution By States
select
l.State,
sum(f.Price_INR) as Total_Revenue 
from fact_swiggy_orders f
join dim_location l on l.Location_id=f.Location_id
group by l.State
order by sum(f.Price_INR) desc
limit 10

--Food Performance

--Top 10 Restaurants By Orders
select
r.Restaurant_Name,
sum(f.Price_INR) as Total_Revenue 
from fact_swiggy_orders f
join dim_restaurant r on r.Restaurant_id=f.Restaurant_id
group by r.Restaurant_Name
order by sum(f.Price_INR) desc
limit 10

-- Top Categories By Order Volume
select 
c.Category,
count(*) as Total_Orders
from fact_swiggy_orders f
join dim_category c on f.Category_id=c.Category_id
group by c.Category 
order by Total_Orders desc
limit 10

--Most Ordered Dishes
select 
d.Dish_Name,
count(*) as Order_Count
from fact_swiggy_orders f
join dim_dish d on d.Dish_id=f.Dish_id
group by d.Dish_Name
order by Order_Count desc
limit 10

--Cuisine Performance (Orders + Avg Rating)
select
c.CAtegory,
count(*) as Total_Orders,
avg(f.Rating) as avg_rating
from fact_swiggy_orders f
join dim_Category c on c.Category_id= f.Category_id
group by c.Category
order by Total_Orders desc

--CUSTOMER SPENDING INSIGHTS
--Buckets of customer spend:-
--    under 100
--    100-199
--    200-299
--    300-499
--    500+       with total order distribution across these ranges.

--Total Orders By Price Range....
select 
  case
      when (Price_INR:: float) <100 then 'Under 100'
	  when (Price_INR:: float) between 100 and 199 then '100-199'
	  when (Price_INR:: float) between 200 and 299 then '200-299'
	  when (Price_INR:: float) between 300 and 399 then '300-399'
	  else '500+'
  end as Price_Range,
  count(*) as Total_Orders
from fact_swiggy_orders f
group by 
   case
      when (Price_INR:: float) <100 then 'Under 100'
	  when (Price_INR:: float) between 100 and 199 then '100-199'
	  when (Price_INR:: float) between 200 and 299 then '200-299'
	  when (Price_INR:: float) between 300 and 399 then '300-399'
	  else '500+'
   end	
order by Total_Orders desc
   
--RATING ANALYSIS

--Rating Count Distribution(1-5)
select
Rating,
count(*) as Rating_Count
from fact_swiggy_orders
group by Rating
order by Rating_Count desc

--end..........................................




