/*1 Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/

SELECT market FROM dim_customer 
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market
ORDER BY market ;

/* 2) What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

SELECT X.A AS unique_product_2020, Y.B AS unique_products_2021, Round((B-A)*100/A,2) AS differnece_chg
FROM
     (
      (SELECT count(DISTINCT(product_code)) AS A FROM fact_sales_monthly
       WHERE fiscal_year = 2020) X,
      (SELECT count(DISTINCT(product_code)) AS B FROM fact_sales_monthly
       WHERE fiscal_year = 2021) Y 
	 );
     
	
 /* 3) Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */

select distinct(segment) as segment, count(distinct(product_code)) as product_counts
 from dim_product
group by segment
order by product_counts desc;

/* 4) Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/


SELECT X.C as segment, X.A AS unique_product_2020, Y.B AS unique_products_2021, (B-A)AS difference_chg
FROM
     (
      (SELECT p.segment as C, count(DISTINCT(product_code)) AS A FROM fact_sales_monthly
       join dim_product p using(product_code)
      WHERE fiscal_year = 2020
      group by p.segment) X,
      (SELECT p.segment as D, count(DISTINCT(product_code)) AS B FROM fact_sales_monthly
       join dim_product p using(product_code)
       WHERE fiscal_year = 2021
       group by p.segment)Y
	 );



/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/

SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F JOIN dim_product P
using(product_code)
WHERE manufacturing_cost in
(
 select max(manufacturing_cost) from fact_manufacturing_cost
union
select min(manufacturing_cost) from fact_manufacturing_cost

)
order by manufacturing_cost;


/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

with TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B FROM fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
     TBL2 AS
(SELECT customer_code AS C, customer AS D FROM dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer, ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5 ;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/


SELECT CONCAT(MONTHNAME(FS.date),YEAR(FS.date) ) AS 'Month', FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS
JOIN dim_customer C  using(customer_code)
JOIN fact_gross_price G using(product_code)
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year ;



/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/


select
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,
    SUM(sold_quantity) AS tsq
from fact_sales_monthly
where fiscal_year = 2020
group by Quarters
order by tsq desc;


/*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

WITH channels as
 (SELECT 
   channel,
   Round((SUM(sold_quantity * gross_price) / 1000000),2) as gross_sales_mln
	FROM fact_sales_monthly as fm
	JOIN fact_gross_price as fp
	using(product_code)
	JOIN dim_customer as dc
	using(customer_code)
	WHERE fm.fiscal_year = 2021
	GROUP BY channel
	ORDER BY gross_sales_mln DESC )

SELECT *,
		ROUND(gross_sales_mln * 100 / 
        (SELECT SUM(gross_sales_mln) FROM channels) ,2) as pct_contributions
FROM channels;


/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order*/ 

WITH cte AS 
(
SELECT P.division, FS.product_code, P.product, SUM(FS.sold_quantity) AS Total_sold_quantity
FROM dim_product P JOIN fact_sales_monthly FS
ON P.product_code = FS.product_code
WHERE FS.fiscal_year = 2021 
GROUP BY  FS.product_code, division, P.product
),
cte2 AS 
(
SELECT division, product_code, product, Total_sold_quantity,
    RANK() OVER(PARTITION BY division ORDER BY Total_sold_quantity DESC) AS rank_Order
FROM Output1
)
 SELECT cte.division, cte.product_code, cte.product, cte2.Total_sold_quantity, cte2.Rank_Order
 FROM cte JOIN cte2
 using(product_code)
WHERE cte2.Rank_Order IN (1,2,3);



























