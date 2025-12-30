-- Assignment 1: Numeric Functions

-- Connect to database
USE maven_advanced_sql;

-- Visualize tables
SELECT * FROM products;
SELECT * FROM orders;

-- Calculate how much every customer has spent
WITH tot_ppr AS (SELECT	o.customer_id, o.units, p.unit_price,
						o.units * p.unit_price AS total_product_price
				 FROM	orders o LEFT JOIN products p 
						ON o.product_id = p.product_id)

SELECT	 customer_id, SUM(total_product_price) AS total_spend_customer
FROM	 tot_ppr
GROUP BY customer_id
ORDER BY total_spend_customer DESC;

-- Bin the customers on how much they have spent with bin range 10$
WITH tot_ppr AS (SELECT	o.customer_id, o.units, p.unit_price,
						o.units * p.unit_price AS total_product_price
				 FROM	orders o LEFT JOIN products p 
						ON o.product_id = p.product_id),
                        
	 cust_spend AS (SELECT 	 FLOOR(SUM(total_product_price)/10)*10 AS total_spend_bin
				    FROM	 tot_ppr
                    GROUP BY customer_id)

SELECT	 total_spend_bin, COUNT(total_spend_bin) AS num_customers
FROM	 cust_spend
GROUP BY total_spend_bin
ORDER BY total_spend_bin;


-- Assignment 2: Datetime Functions

-- Visualize table
SELECT * FROM orders;

-- Extract orders for Q2 of 2024 and add ship_date that is 2 days after order_date
SELECT	 order_id, order_date, 
		 DATE_ADD(order_date, INTERVAL 2 DAY) AS ship_date
FROM 	 orders
WHERE	 YEAR(order_date) = 2024 AND MONTH(order_date) BETWEEN 4 and 6
ORDER BY order_date;


-- Assignment 3: String Functions 

-- Visualize table
SELECT * FROM products;

-- Create a new column with the factory and product_id
SELECT	 factory, product_id,
		 CONCAT(REPLACE(REPLACE(factory, "'", ""), " ", "-"), "-", product_id)
FROM	 products
ORDER BY factory, product_id;


-- Assignment 4: Pattern Matching

-- Visualize table
SELECT * FROM products;

-- Remove Wonka Bar from the product_name
SELECT 	 product_name,
		 REPLACE(product_name, "Wonka Bar - ", "") AS new_product_name
FROM	 products
ORDER BY product_name DESC;

-- Alternative (general)
SELECT	 product_name,
		 CASE WHEN INSTR(product_name, "-") = 0 THEN product_name
			  ELSE SUBSTR(product_name, INSTR(product_name, "-") + 2)
              END AS new_product_name
FROM 	 products
ORDER BY product_name DESC;


-- Assignment 5: Null Functions

-- Visualize table 
SELECT * FROM products;

-- Update NULL values to "Other"
SELECT	 product_name, factory, division,
		 COALESCE(division, "Other") AS division_other
FROM 	 products
ORDER BY factory, division;

-- Find the most popular division for each factory
WITH count_div AS (SELECT 	factory, division,
							COUNT(product_name) AS num_div
				   FROM 	products
                   WHERE 	division IS NOT NULL
                   GROUP BY factory, division)

SELECT	 factory, division,
		 DENSE_RANK() OVER(PARTITION BY factory ORDER BY num_div DESC) AS popularity_rank
FROM	 count_div
ORDER BY factory, popularity_rank;

-- Update NULL values to be the same division as the most common division of their factories
WITH count_div AS (SELECT 	factory, division,
							COUNT(product_name) AS num_div
				   FROM 	products
                   WHERE 	division IS NOT NULL
                   GROUP BY factory, division),

	 pop_div AS (SELECT	factory, division,
						DENSE_RANK() OVER(PARTITION BY factory ORDER BY num_div DESC) AS popularity_rank
				 FROM	count_div),

	 return_pop_div AS (SELECT 	factory, division
						FROM 	pop_div
                        WHERE 	popularity_rank = 1)

SELECT	 p.product_name, p.factory, p.division, 
		 COALESCE(p.division, "Other") AS division_other,
         COALESCE(p.division, rpd.division) AS division_top
FROM 	 products p LEFT JOIN return_pop_div rpd
		 ON p.factory = rpd.factory
ORDER BY p.factory, p.division;