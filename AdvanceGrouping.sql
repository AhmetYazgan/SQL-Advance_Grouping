--GROUPING OPERATIONS

--HAVING

--QUESTION: Write a query that checks if any product id is duplicated in product table.
SELECT product_id, COUNT(*) row_cnt
FROM product.product
GROUP BY product_id
HAVING COUNT(product_id)>1

--Write a query that returns category ids with conditions max list price above 4000 or a min list price below 500.
SELECT category_id, MAX(list_price) max_price, MIN(list_price) min_price
FROM product.product
GROUP BY category_id
HAVING MAX(list_price) > 4000 OR MIN(list_price) < 500


SELECT *
FROM (SELECT category_id, MAX(list_price) max_price, MIN(list_price) min_price
FROM product.product
GROUP BY category_id) subq
WHERE max_price > 4000 OR min_price < 500

--Find the average product prices of the brands. Display brand name and average prices in descending order.
SELECT brand_id, AVG(list_price) avg_price
FROM product.product
GROUP BY brand_id
ORDER BY avg_price DESC;

--Write a query that returns the list of brands whose average product prices are more than 1000

SELECT *
FROM (
		SELECT brand_id, AVG(list_price) avg_price
		FROM product.product
		GROUP BY brand_id) SUBQ
WHERE avg_price > 1000
ORDER BY avg_price DESC;


SELECT brand_id, AVG(list_price) avg_price
FROM product.product
GROUP BY brand_id
HAVING AVG(list_price) > 1000
ORDER BY avg_price DESC;


SELECT *
FROM (
		SELECT brand_name, b.brand_id, AVG(list_price) avg_price
		FROM product.product p, product.brand b
		WHERE p.brand_id=b.brand_id
		GROUP BY brand_name, b.brand_id) SUBQ
WHERE avg_price > 1000
ORDER BY avg_price DESC;

SELECT brand_name, b.brand_id, AVG(list_price) avg_price
FROM product.product p, product.brand b
WHERE p.brand_id=b.brand_id
GROUP BY brand_name, b.brand_id
HAVING AVG(list_price) > 1000


--Write a query that returns the list of each order id and that order's total net price (please take into consideration of discounts and quantities)

SELECT order_id, SUM(quantity*list_price*(1-discount)) total_price
FROM sale.order_item
GROUP BY order_id

--Write a query that returns monthly order counts of the States.
SELECT c.state, YEAR(order_date) ord_year ,MONTH(order_date) ord_month, COUNT(order_id) ord_cnt
FROM sale.orders o, sale.customer c
WHERE o.customer_id=c.customer_id
GROUP BY c.state, YEAR(order_date), MONTH(order_date)
ORDER BY c.state, ord_year, ord_month


--GROUPING SETS

--1. Calculate the total sales price.
SELECT SUM(list_price*quantity*(1-discount)) total_sales_price
FROM sale.order_item


--2. Calculate the total sales price of the brands
SELECT b.brand_name, p.brand_id, SUM(i.list_price*quantity*(1-discount)) total_sales_price
FROM sale.order_item i, product.product p, product.brand b
WHERE i.product_id=p.product_id AND p.brand_id=b.brand_id
GROUP BY b.brand_name, p.brand_id


--3. Calculate the total sales price of the model year
SELECT model_year, SUM(i.list_price*quantity*(1-discount)) total_sales_price
FROM sale.order_item i, product.product p
WHERE p.product_id=i.product_id
GROUP BY model_year


--4. Calculate the total sales price by brands and model year.
SELECT brand_name, model_year, SUM(i.list_price*quantity*(1-discount)) total_sales_price
FROM sale.order_item i, product.product p, product.brand b
WHERE i.product_id=p.product_id AND p.brand_id=b.brand_id
GROUP BY brand_name, model_year
ORDER BY brand_name, model_year


--GROUPING SETS ()
SELECT brand_name, model_year, SUM(i.list_price*quantity*(1-discount)) total_sales_price,
		GROUPING(b.brand_name) brand_gr, 
		GROUPING(model_year) model_gr
FROM sale.order_item i, product.product p, product.brand b
WHERE i.product_id=p.product_id AND p.brand_id=b.brand_id
GROUP BY 
		GROUPING SETS(
				(),
				(brand_name),
				(model_year),
				(brand_name, model_year)
		)
HAVING
		GROUPING(b.brand_name) = 0 AND
		GROUPING(model_year) = 0
ORDER BY brand_name, model_year
--we found here that used both grouping

--Deleting NULL values using by HAVING key
SELECT brand_name, model_year, SUM(i.list_price*quantity*(1-discount)) total_sales_price
FROM sale.order_item i, product.product p, product.brand b
WHERE i.product_id=p.product_id AND p.brand_id=b.brand_id
GROUP BY 
		GROUPING SETS(
				(),
				(brand_name),
				(model_year),
				(brand_name, model_year)
		)
HAVING brand_name IS NOT NULL AND model_year IS NOT NULL
ORDER BY brand_name, model_year


--Deleting NULL values using by WHERE key
SELECT brand_name, model_year, total_sales_price
FROM (
    SELECT brand_name, model_year, SUM(i.list_price * quantity * (1 - discount)) AS total_sales_price
    FROM sale.order_item i
    JOIN product.product p ON i.product_id = p.product_id
    JOIN product.brand b ON p.brand_id = b.brand_id
    GROUP BY GROUPING SETS (
        (),
        (brand_name),
        (model_year),
        (brand_name, model_year)
    )
) AS subq
WHERE brand_name IS NOT NULL AND model_year IS NOT NULL
ORDER BY brand_name, model_year;


--Combine these 4 tables using by UNION key
SELECT SUM(list_price*quantity*(1-discount)) AS total_sales_price, NULL AS brand_name, NULL AS model_year
FROM sale.order_item

UNION

SELECT SUM(i.list_price*quantity*(1-discount)), b.brand_name, NULL
FROM sale.order_item i
JOIN product.product p ON i.product_id = p.product_id
JOIN product.brand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name

UNION

SELECT SUM(i.list_price*quantity*(1-discount)), NULL, p.model_year
FROM sale.order_item i
JOIN product.product p ON i.product_id = p.product_id
GROUP BY p.model_year

UNION

SELECT SUM(i.list_price*quantity*(1-discount)), b.brand_name, p.model_year
FROM sale.order_item i
JOIN product.product p ON i.product_id = p.product_id
JOIN product.brand b ON p.brand_id = b.brand_id
GROUP BY b.brand_name, p.model_year
ORDER BY brand_name, model_year;



--SUMMARY TABLE

--brand, category, model_year, total_sales_price

/*
SELECT ...
INTO	...
FROM ....
*/


SELECT brand_name, c.category_name, model_year, SUM(i.list_price*quantity*(1-discount)) total_sales_price
INTO sale.sales_summary
FROM sale.order_item i, product.product p, product.brand b, product.category c
WHERE i.product_id=p.product_id AND p.brand_id=b.brand_id AND p.category_id=c.category_id
GROUP BY brand_name, c.category_name, model_year
ORDER BY brand_name, c.category_name, model_year


SELECT *
FROM sale.sales_summary


--Question: Write a query using summary table that returns the total total_sales from each category by model year. (in pivot table format)
--WITH brand_name
SELECT *
FROM (
		SELECT brand_name, model_year, total_sales_price
		FROM sale.sales_summary
		)subq
PIVOT
(
	SUM(total_sales_price)
	FOR model_year
	IN ([2018],[2019],[2020],[2021])
) PV_TABLE

--WITHOUT brand_name
SELECT *
FROM (
		SELECT model_year, total_sales_price
		FROM sale.sales_summary
		)subq
PIVOT
(
	SUM(total_sales_price)
	FOR model_year
	IN ([2018],[2019],[2020],[2021])
) PV_TABLE

--CREATING VIEW
CREATE VIEW VW_TOTAL_SALES AS
SELECT brand_name, model_year, total_sales_price
FROM sale.sales_summary

--USING BY VIEW
SELECT *
FROM VW_TOTAL_SALES
PIVOT
(
	SUM(total_sales_price)
	FOR model_year
	IN ([2018],[2019],[2020],[2021])
) PV_TABLE


--Write a query that returns count of the orders day by day in a pivot table format that has been shipped two days later.



SELECT DATENAME(WEEKDAY, order_date) date_of_week, COUNT(order_id) cnt_order_by_day
FROM sale.orders o
WHERE DATEDIFF(DAY, order_date, shipped_date) > 2
GROUP BY DATENAME(WEEKDAY, order_date)


SELECT *
FROM
	(
	SELECT DATENAME(WEEKDAY, order_date) date_of_week, order_id
	FROM sale.orders
	WHERE DATEDIFF(DAY, order_date, shipped_date) > 2
	) A
PIVOT
	(
	COUNT(order_id)
	FOR date_of_week 
	IN ([Monday], [Tuesday],[Wednesday],[Thursday],[Friday],[Saturday],[Sunday])
	) PVT