/*
PROJECT: Volkswagen Sales Analysis — SQL Preparation and Validation
PLATFORM: Microsoft SQL Server 2022

PURPOSE
This script documents the exploratory data checks, proposed data-quality
corrections, validation queries, sales analysis, and supporting objects used
for the Volkswagen Power BI dashboard.

NOTES
- Review each result set before applying any UPDATE or DELETE statement.
- Data-changing statements are retained as comments for transparency.
- The dataset is illustrative/synthetic and is intended for portfolio analysis.
- Some checks and corrections are exploratory; see the notes beside each section.
*/

-- ============================================================
-- 00. INITIAL DATA REVIEW
-- Inspect the source tables to understand their structure and contents.
-- ============================================================
select * from cars
select * from car_colours
select * from customers
select * from Dealers
select * from sales

-- ============================================================
-- 01. FUEL-TYPE CONSISTENCY CHECK
-- Review the distinct fuel values and identify inconsistent labels.
-- The UPDATE statements below are commented out for review before execution.
-- ============================================================
select distinct fuel_type from  cars

--update cars set fuel_type='Petrol' where fuel_type='P' ---(1 row affected)


-- ============================================================
-- 02. CUSTOMER DATA COMPLETENESS
-- Count NULL values in each customer attribute to assess data completeness.
-- The aliases identify the column being checked and the NULL count returned.
-- ============================================================
select 
sum(case when customer_id is null then 1 else 0 end) customer_id_null,
sum(case when customer_name is null then 1 else 0 end) cust_name_null,
sum(case when age is null then 1 else 0 end) cust_age_null,
sum(case when gender is null then 1 else 0 end) cust_gender_null,
sum(case when city is null then 1 else 0 end) cust_city_null,
sum(case when state is null then 1 else 0 end) cust_state_null,
sum(case when occupation is null then 1 else 0 end) cust_occupation_null from customers

-- ============================================================
-- 03. GENDER VALUE STANDARDIZATION
-- Inspect distinct gender labels and identify abbreviated values.
-- The commented UPDATE statements show the proposed standardization.
-- ============================================================
select distinct gender from customers
--update customers set gender='Male' where gender='M'
--update customers set gender='Female' where gender='F'

-- ============================================================
-- 04. SALES DATA COMPLETENESS
-- Count missing values in key sales, customer, dealer, vehicle, pricing,
-- payment, and location columns. Use these counts to prioritize investigation.
-- ============================================================

select sum(case when sale_id is null then 1 else 0 end) sale_id_null,
sum(case when sale_date is null then 1 else 0 end)sale_date_null,
sum(case when dealer_id is null then 1 else 0 end) dealer_id_null, ----243 rows
sum(case when car_id is null then 1 else 0 end) car_id_null,
sum(case when Colour_id is null then 1 else 0 end) Colour_id_null,
sum(case when city is null then 1 else 0 end) city_null,
sum(case when state is null then 1 else 0 end) state_null,
sum(case when units_sold is null then 1 else 0 end) units_sold_null,
sum(case when listed_price is null then 1 else 0 end) listed_price_null,
sum(case when discount is null then 1 else 0 end) discount_null, ----400 rows
sum(case when selling_price is null then 1 else 0 end) selling_price_null,
sum(case when revenue is null then 1 else 0 end) revenue_null,
sum(case when payment_type is null then 1 else 0 end) payment_type_null ----483 rows
from sales  

-- Inspect distinct dealer IDs and review records with missing critical values.
-- These queries help identify affected rows for further investigation.
-- Comments such as "Done" record the original working notes; confirm the
-- current database state before treating a missing-value issue as resolved.
select distinct dealer_id from sales
select * from sales where discount is null ---Done
select * from sales where dealer_id is null ---243 Done
select * from sales where payment_type is null --483 

-- ============================================================
-- 05. ZERO VALUES IN PRICING COLUMNS
-- Inspect records where listed price, selling price, or discount is zero.
-- A zero may be valid or may indicate a data-quality issue, so review context
-- before deciding whether a correction is required.
-- ============================================================ 
select * from sales where listed_price=0 or selling_price=0 or discount=0 --40 records zero for selling_price and 1 record for discount

-- ============================================================
-- 06. PRICING LOGIC VALIDATION
-- Compare the stored discount with (listed_price - selling_price), then
-- summarize how many records satisfy the expected relationship.
-- ============================================================
select * from sales where discount<>(listed_price-selling_price)
select count(*) as total_records,sum(case when discount=listed_price-selling_price then 1 else 0 end ) as matching_records from sales

--update sales set discount=(listed_price-selling_price) where discount is null
--update sales set selling_price=(listed_price-discount) where selling_price=0


-- ============================================================
-- 07. INVESTIGATING MISSING DEALER IDs
-- Review sales without a dealer ID and explore whether city can help match them to a dealer. 
-- ============================================================
select * from sales where dealer_id is null ---243

select s.dealer_id,d.dealer_id,d.dealer_name,* from sales s join Dealers d on s.city=d.city where s.dealer_id is null
--update s set s.dealer_id=d.dealer_id from sales s join Dealers d on s.city=d.city where s.dealer_id is null


-- ============================================================
-- 08. CITY AND STATE STANDARDIZATION
-- Review distinct city/state values and identify abbreviations or alternate
-- spellings. The commented UPDATE statements document proposed standard forms.
-- ============================================================

select distinct city from sales order by city 
--update sales set city='Bangalore' where city in ('Bengaluru','B''lore') 

select distinct state from sales order by state
--update sales set state='Delhi' where state='DL'
--update sales set state='Karnataka' where state='KA'
--update sales set state='Maharashtra' where state='MH'
--update sales set state='Tamil Nadu' where state='TN'
--update sales set state='Telangana' where state='TS'


-- ============================================================
-- 09. SALES DUPLICATE CHECK
-- Use ROW_NUMBER() to flag repeated sale_id values for investigation.
-- Review flagged rows and decide which record should be retained before deletion.
-- ============================================================
with Sales_dup as(
select *,row_number() over (partition by sale_id order by sale_id ) as rnk from Sales
)
select * from Sales_dup where rnk>1
order by rnk desc
--delete from Sales_dup where rnk>1

-- ============================================================
-- 10. CUSTOMER DUPLICATE CHECK
-- Use ROW_NUMBER() to flag repeated customer_id values for investigation.
-- Confirm whether repeated IDs represent true duplicate records before removal.
-- ============================================================
with customer_dup as(
select *,row_number() over (partition by customer_id order by customer_id ) as rnk from Customers
)
select * from customer_dup where rnk>1
order by rnk desc

with customer_dup as(
select *,row_number() over (partition by customer_id order by customer_id ) as rnk from Customers
)
select * from customer_dup where rnk>1 order by rnk desc
--delete from customer_dup where rnk>1

-- ============================================================
--Identifying Potential Duplicate Sales Transactions
-- Detecting cases where the same customer may have purchased the same car
-- from the same dealer on the same date, with duplicate entries potentially
-- caused by accidental double entry by the operations team.
-- ============================================================

select sale_date,customer_id,dealer_id,car_id,Colour_id,city,state,units_sold,listed_price,discount,selling_price,
revenue,payment_type from sales group by 
sale_date,customer_id,dealer_id,car_id,Colour_id,city,state,units_sold,listed_price,discount,selling_price,
revenue,payment_type
having count(customer_id)>1

-- ============================================================
-- 11. KPI VALIDATION AND BUSINESS ANALYSIS
-- The following aggregate queries support cross-checking the Power BI measures
-- and exploring sales performance across key business dimensions.
-- ============================================================

-- 11.1. OVERALL KPI TOTALS
-- Calculate total revenue, units sold, average selling price, total & average
-- discount, and distinct customers for high-level dashboard KPI comparisons.
-- ============================================================

select sum(cast (revenue as bigint)) Revenue,sum(units_sold) unit_sold,avg(cast (selling_price as bigint)) avg_selling_price,sum(cast (discount as bigint)) Discount,
avg(cast(discount as bigint)) Avg_Discount,count(distinct customer_id) Customers from Sales


-- 11.2. MODEL-WISE SALES PERFORMANCE
-- Compare revenue, units sold, and customer counts across vehicle models.
-- Results can be used to validate model-level visuals in Power BI.
-- ============================================================
select sum(cast (revenue as bigint)) Revenue,sum(units_sold) Unit_Sold,count(customer_id) No_Of_Customers,model from sales s join cars c on s.car_id=c.car_id
group by model

-- 11.3. COLOUR- AND MODEL-WISE SALES
-- Break down revenue, units sold, and customer counts by vehicle colour and
-- model to support colour/model comparisons in the dashboard.
-- ============================================================
select sum(cast (revenue as bigint)) Revenue,sum(units_sold ) unit_sold,count(distinct customer_id) No_Of_Customers,Colour,model 
from sales s join car_colours cc on s.colour_id=cc.colour_id
join cars c on c.car_id=s.car_id
group by Colour,model
order by Colour

-- 11.4. SALES BY FUEL TYPE
-- Compare model-level revenue, units sold, and customers across fuel types.
-- ============================================================

select Model,sum(cast (revenue as bigint)) revenue,sum(units_sold) unit_sold,count(distinct customer_id) customers,fuel_type 
from sales s join cars c  on s.car_id=c.car_id --where fuel_type='Petrol'
group by Model,fuel_type

-- 11.5. SALES BY TRANSMISSION
-- Compare model-level revenue, units sold, and customers by transmission type.
-- ============================================================
select Model,sum(cast (revenue as bigint)) revenue,sum(units_sold) unit_sold,count(distinct customer_id) customers,transmission 
from sales s join cars c  on s.car_id=c.car_id --where transmission='Manual'
group by Model,transmission

-- 11.6. SALES BY VEHICLE VARIANT
-- Compare revenue, units sold, and customer counts by model and variant.
-- ============================================================
select Model,sum(cast (revenue as bigint)) revenue,sum(units_sold) unit_sold,count(distinct customer_id) customers,variant 
from sales s  join cars c  on s.car_id=c.car_id 
group by Model,variant
order by variant


-- ============================================================
-- 12. POWER BI IMAGE URL SUPPORT
-- Create a lookup table that stores a model, colour, and corresponding image
-- URL. Power BI can use this mapping to display the appropriate vehicle image.
-- ============================================================
create table colour_images_Url (
Model varchar(50),colour varchar(100),Image_Url varchar(Max)
)

--Insert into colour_images_Url select distinct model,colour,Null as Image_Url from sales s join cars c on c.car_id=s.car_id
--join car_colours cc on cc.Colour_id=s.Colour_id

select * from colour_images_Url where colour='candy white'

--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Virtus.png' where Model='Virtus' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Ameo.png' where Model='Ameo' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Taigun.png' where Model='Taigun' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Tiguan.png' where Model='Tiguan' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20T-Roc.png' where Model='T-Roc' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Polo.png' where Model='Polo' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Jetta.png' where Model='Jetta' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Passat.png' where Model='Passat' and colour='Default white'
--update colour_images_Url set image_url='https://raw.githubusercontent.com/Gowtham-Rr/Volkswagen-BI-Project/main/VW%20Car%20Color%20Images/VW%20White%20Images/White%20Vento.png' where Model='Vento' and colour='Default white'


-- ============================================================
-- 13. MODEL IMAGE VIEW
-- This view exposes colour and image URL values for the All models.
-- ============================================================

CREATE VIEW vw_Virtus_Image
AS
SELECT
    colour,
    Image_URL
FROM colour_images_Url
WHERE Model = 'Virtus';


SELECT * FROM colour_images_Url
ORDER BY Model, colour;

-- ============================================================
-- 14. YEARLY REVENUE TREND
-- Aggregate revenue by calendar year to review historical performance.
-- Interpret 2026 as a partial year because the available data ends during 2026;
-- use comparable year-to-date periods for a fairer year-over-year comparison.
-- ============================================================

select sum(cast (revenue as bigint)) to_revenue,year(sale_date) yr from sales
group by year(sale_date)
order by yr

/*
YEAR-TO-DATE COMPARISON NOTE
The dataset contains sales through September-15-2026, so I treated 2026 as a partial year. Instead of comparing 9 months of 2026 
against the full 12 months of 2025, I used year-to-date revenue and compared it with the equivalent period of 2025. This gives a 
fairer view of the current sales performance, while acknowledging that the remaining 3.5 months of 2026 can still change the 
full-year result.”
*/
select min(sale_date) min_dtae,max(sale_date) max_date from sales


-- ============================================================
-- 15. YEARLY UNIT SALES
-- Aggregate units sold by year and provide a comparable-period check for 2025.
-- ============================================================

select sum(units_sold) total_car_sold,year(sale_date) yr from sales
group by year(sale_date)
order by yr

select sum(units_sold) total_car_sold from sales where sale_date between '2025-01-01' and '2025-09-15'

-- ============================================================
-- 16. YEARLY REVENUE AND UNITS SOLD
-- Return yearly revenue and unit totals as a basis for calculating revenue per
-- unit or validating yearly measures in the Power BI report.
-- ============================================================

select sum(cast (revenue as bigint)) revenue,sum(units_sold) Unit_Sold,year(sale_date) year from Sales
group by year(sale_date)
order by year


-- ============================================================
-- 17. YEARLY UNIQUE CUSTOMER COUNTS
-- Count distinct non-NULL customer IDs by sale year to compare customer reach
-- across years and validate the corresponding Power BI analysis.
-- ============================================================

select count(distinct customer_id) No_Of_Customers,year(sale_date) Yr from sales
group by year(sale_date)
order by yr