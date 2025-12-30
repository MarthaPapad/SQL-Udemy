-- Assignment 1: Subqueries in the SELECT clause

-- Connect to database
USE maven_advanced_sql;

-- Visualize table
SELECT * FROM products;

-- Use subquery to list products most to least expensive, with the difference from the average
SELECT	 product_id, product_name, unit_price,
		 (SELECT AVG(products.unit_price) FROM products) AS avg_unit_price,
         unit_price - (SELECT AVG(unit_price) FROM products) AS diff_price
FROM	 products
ORDER BY unit_price DESC;


-- Assignment 2: Subqueries in the FROM clause

-- Visualize table
SELECT * FROM products;

-- Count the products of each factory
SELECT	 factory, COUNT(product_id) AS num_products
FROM 	 products
GROUP BY factory;

-- Use subquery to list factories, product names and number of products 
SELECT 	 pr.factory, pr.product_name, np.num_products
FROM 	 products pr
		 LEFT JOIN 
         (SELECT	factory, COUNT(product_id) AS num_products
		  FROM 	products
		  GROUP BY factory) AS np
		 ON pr.factory = np.factory
ORDER BY pr.factory, pr.product_name;


-- Assignment 3: Subqueries in the WHERE clause

-- Visualize table
SELECT * FROM products;

-- Find all Wicked Choccy's products
SELECT 	* 
FROM 	products 
WHERE	factory = "Wicked Choccy's";

-- Use subquery to find products that have less unit price than the products of Wicked Choccy's
SELECT 	*
FROM 	products
WHERE	unit_price < ALL (SELECT unit_price 
						  FROM	 products 
						  WHERE	 factory = "Wicked Choccy's");
                            

-- Assignment 4: CTEs

-- Visualize tables
SELECT * FROM products;
SELECT * FROM orders;

-- Calculate the price for all units of a product_id
SELECT	ord.order_id, pr.unit_price, ord.units,
		pr.unit_price * ord.units AS products_price
FROM	orders ord INNER JOIN products pr
		ON pr.product_id = ord.product_id;

-- Calculate the total price of each order and filter for over 200$
SELECT	 ord.order_id, 
		 SUM(pr.unit_price * ord.units) AS total_amount_spent
FROM	 orders ord INNER JOIN products pr
		 ON pr.product_id = ord.product_id
GROUP BY ord.order_id
HAVING 	 total_amount_spent > 200
ORDER BY total_amount_spent DESC;

-- Create CTE to count how many orders are above 200$
WITH orders_price AS (SELECT	ord.order_id, 
								SUM(pr.unit_price * ord.units) AS total_amount_spent
					  FROM		orders ord INNER JOIN products pr
								ON pr.product_id = ord.product_id
					  GROUP BY 	ord.order_id
					  HAVING 	total_amount_spent > 200)
                     
SELECT	COUNT(*)
FROM 	orders_price;


-- Assignment 5: Multiple CTEs

-- Rewrite the Assignment 2 to have multiple CTEs instead of subqueries
WITH pr AS (SELECT	 factory, product_name
			FROM	products),
	 np AS (SELECT	 factory, COUNT(product_id) AS num_products
			FROM 	 products
			GROUP BY factory)

SELECT 	 pr.factory, pr.product_name, np.num_products
FROM 	 pr LEFT JOIN np
		 ON pr.factory = np.factory
ORDER BY pr.factory, pr.product_name;