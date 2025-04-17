CREATE database coffeeshop;
USE coffeeshop;
--  Coffeeshop SCHEMAS


-- Create Rules
-- 1st create to city
-- 2nd create to products
-- 3rd create to customers
-- 4th create to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);
-- IMPORT Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Q1 how namy people in each city are estimated to consume coffee, given that 25% of population does?
SELECT city_name,ROUND((population*0.25)/1000000 ) as c_consumer_mln,city_rank
FROM city
ORDER BY population DESC;
-- Q2 TOTAL REVENUE FROM COFFEE SALES?
SELECT ci.city_name,sum(s.total) as total_revenue FROM sales  as s
JOIN customers as c
ON s.customer_id=c.customer_id 
JOIN city as ci
ON c.city_id=ci.city_id
WHERE quarter(s.sale_date)=4 and YEAR(s.sale_date)=2023
GROUP BY ci.city_name
ORDER BY SUM(s.total) DESC;

-- Q3 HOW Many units of each coffee product has been sold?

SELECT p.product_name,count(s.sale_id) as total_orders FROM products as p
LEFT JOIN sales as s
ON s.product_id=p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q4 avg sales amnt per customer in each city?
SELECT ci.city_name,sum(s.total) as total_revenue,COUNT(DISTINCT(s.customer_id)) as total_customer,round(sum(s.total)/COUNT(DISTINCT(s.customer_id)),1) as avg_per_cust FROM sales  as s
JOIN customers as c
ON s.customer_id=c.customer_id 
JOIN city as ci
ON c.city_id=ci.city_id
GROUP BY ci.city_name
ORDER BY SUM(s.total) DESC; 

-- Q5 city population and coffee consumers(list of cities with  their population,coffee consumers)?

WITH my_cte as(SELECT city_name,ROUND((population*0.25)/1000000 ,2) as c_consumer_mln FROM city),
cust_table as (select ci.city_name,count(distinct(c.customer_id)) as unique_cust
 FROM sales  as s
JOIN customers as c
ON c.customer_id=s.customer_id 
JOIN city as ci
ON ci.city_id=c.city_id
GROUP BY ci.city_name)
select ct.city_name, ct.c_consumer_mln, cit.unique_cust
from my_cte as ct
JOIN cust_table as cit
ON cit.city_name=ct.city_name;

-- Q6 how many unique customers are there in each city who have purchased coffee product?

select ci.city_name,count(distinct(c.customer_id)) as unique_cust
 FROM city  as ci
 LEFT JOIN customers as c
ON c.city_id=ci.city_id 
JOIN sales as s
ON s.customer_id=c.customer_id
JOIN products as p
ON p.product_id=s.product_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name;

-- Q7 calculate percentage growth in sales over different time periods by each city?

WITH MONTHLY_SALES AS (SELECT ci.city_name,MONTH(sale_date) as month, YEAR(sale_date) as year,sum(s.total) as total_sales FROM sales as s
JOIN customers as c
ON c.customer_id=s.customer_id
JOIN city as ci
ON ci.city_id=c.city_id
GROUP BY ci.city_name,MONTH(sale_date), YEAR(sale_date)
ORDER BY ci.city_name, YEAR(sale_date),MONTH(sale_date) ASC
),
growth_ratio AS (
SELECT
city_name,
month,
year,
total_sales as cr_month_sales,
LAG(total_sales,1) OVER(PARTITION BY city_name ORDER BY year,month) as last_month_sales
FROM MONTHLY_SALES)
SELECT 
city_name,month,
year,
cr_month_sales,
last_month_sales,
ROUND((cr_month_sales-last_month_sales)/last_month_sales*100,2)as growth_ratio

FROM  growth_ratio
WHERE last_month_sales IS NOT NULL;

