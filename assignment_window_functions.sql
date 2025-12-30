-- Assignment 1: Window Functions Basics

-- Connect to database
USE maven_advanced_sql;

-- Visualize table
SELECT * FROM orders;

-- Add a column for the transaction number of each costumer
SELECT 	customer_id, order_id, order_date, transaction_id,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY transaction_id) AS transaction_number
FROM 	orders;


-- Assignment 2: Row Numbering

-- Visualize table
SELECT * FROM orders;

-- Add a column for the products' rank of each order
SELECT	 order_id, product_id, units,
		 DENSE_RANK() OVER (PARTITION BY order_id ORDER BY units DESC) AS product_rank
FROM 	 orders
ORDER BY order_id, product_rank;


-- Assignment 3: Value within a Window Function

-- Visualize table 
SELECT * FROM orders;

-- Get second most popular product of each order with DENSE_RANK()
WITH pr AS (SELECT	order_id, product_id, units,
			DENSE_RANK() OVER (PARTITION BY order_id ORDER BY units DESC) AS product_rank
			FROM 	orders)

SELECT 	 order_id, product_id, units
FROM 	 pr
WHERE 	 product_rank = 2
ORDER BY order_id;

-- Alternative way with NTH_VALUE()
WITH pr AS (SELECT	order_id, product_id, units,
			NTH_VALUE(product_id, 2) OVER (PARTITION BY order_id ORDER BY units DESC) AS sec_product
			FROM 	orders)
            
SELECT 	 order_id, product_id, units
FROM 	 pr
WHERE 	 product_id = sec_product
ORDER BY order_id;            


-- Assignment 4: Value relative to a Row

-- Visualize table 
SELECT 	 *
FROM 	 orders
ORDER BY order_id;

-- Calculate total units of each order
SELECT	 customer_id, order_id, MIN(transaction_id) AS min_trans, SUM(units) AS total_units
FROM 	 orders
GROUP BY customer_id, order_id
ORDER BY customer_id, min_trans;

-- Calculate the difference of units of a customers order
WITH ctu AS (SELECT	  customer_id, order_id,
					  MIN(transaction_id) AS min_trans,
					  SUM(units) AS total_units
			 FROM 	  orders
			 GROUP BY customer_id, order_id),
            
	 pu AS (SELECT 	customer_id, order_id, min_trans, total_units,
					LAG(total_units) OVER (PARTITION BY customer_id ORDER BY min_trans) AS prior_units
			FROM 	ctu)
                     
SELECT	customer_id, order_id, total_units, prior_units,
        total_units - prior_units AS  diff_units
FROM 	pu;


-- Assignment 5: Statistical Functions

-- Visualize tables
SELECT * FROM products;
SELECT * FROM orders;

-- Calculate how much every customer has spent
SELECT	 o.customer_id, 
		 SUM(o.units * p.unit_price) AS total_spend
FROM	 orders o LEFT JOIN  products p
		 ON o.product_id = p.product_id
GROUP BY o.customer_id
ORDER BY total_spend DESC;

-- List the top 1% of customers in terms of total_spend
WITH cts AS (SELECT	  o.customer_id, 
					  SUM(o.units * p.unit_price) AS total_spend
			 FROM	  orders o LEFT JOIN  products p
					  ON o.product_id = p.product_id
			 GROUP BY o.customer_id),
             
	 t1p AS (SELECT	  customer_id, total_spend,
					  NTILE(100) OVER (ORDER BY total_spend DESC) AS spend_pct
			 FROM     cts
             ORDER BY total_spend DESC)

SELECT	*
FROM	t1p
WHERE	spend_pct = 1;