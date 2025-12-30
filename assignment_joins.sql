-- Assignment 1: Basic Joins

-- Connect to database
USE maven_advanced_sql;

-- Visualize tables
SELECT * FROM products;
SELECT * FROM orders;

-- View count of distinct product ids in each table
SELECT COUNT(DISTINCT product_id) FROM products;
SELECT COUNT(DISTINCT product_id) FROM orders;

-- Join tables to see which products exist in one table, but not the other
SELECT	pr.product_id, pr.product_name,
		ord.product_id AS product_id_in_orders
FROM	products pr
		LEFT JOIN orders ord
		ON pr.product_id = ord.product_id
WHERE	ord.product_id IS NULL;


-- Assignment 2: Self Joins

-- Visualize table 
SELECT * FROM products;

-- Self Join for products that are within 25 cents unit price 
SELECT	 pr_1.product_name, pr_1.unit_price,
		 pr_2.product_name, pr_2.unit_price,
         pr_1.unit_price - pr_2.unit_price AS price_diff
FROM	 products pr_1 INNER JOIN products pr_2
		 ON pr_1.product_name < pr_2.product_name 
         AND ABS(pr_1.unit_price - pr_2.unit_price) < 0.25
ORDER BY price_diff DESC;