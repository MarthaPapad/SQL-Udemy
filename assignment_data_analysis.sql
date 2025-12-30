-- Assignment 1: Duplicate Values

-- Connect to database
USE maven_advanced_sql;

-- Visualize table
SELECT * FROM students;

-- Remove duplicate values
WITH count_students AS (SELECT 	id, student_name, email,
								ROW_NUMBER() OVER (PARTITION BY student_name, grade_level, gpa, birthday ORDER BY id DESC)
                                AS st_count
						FROM 	students)
                        
SELECT	 id, student_name, email
FROM 	 count_students
WHERE 	 st_count = 1
ORDER BY id;


-- Assignment 2: Min/Max Value Filtering

-- Visualize tables
SELECT * FROM students;
SELECT * FROM student_grades;

-- Get the top grades of each student and the corresponding class
WITH get_top_grade AS (SELECT 	st.id, st.student_name, MAX(sg.final_grade) AS top_grade
					   FROM		students st INNER JOIN student_grades sg
								ON st.id = sg.student_id
					   GROUP BY st.id, st.student_name)

SELECT 	 gtg.id, gtg.student_name, gtg.top_grade, sg.class_name
FROM	 get_top_grade gtg LEFT JOIN student_grades sg
		 ON gtg.id = sg.student_id AND gtg.top_grade = sg.final_grade
ORDER BY gtg.id;

-- Alternative (Window function)
WITH rank_grades AS (SELECT student_id, final_grade, class_name,
							DENSE_RANK() OVER (PARTITION BY student_id ORDER BY final_grade DESC) AS grade_rank
					 FROM	student_grades)

SELECT 	s.id, s.student_name, rg.final_grade, rg.class_name
FROM 	rank_grades rg LEFT JOIN students s
		ON rg.student_id = s.id
WHERE 	rg.grade_rank = 1;


-- Assiignment 3: Pivoting

-- Visualize tables
SELECT * FROM student_grades;
SELECT * FROM students;

-- Create a summary table of grades for every department
SELECT 	 sg.department,
		 ROUND(AVG(CASE WHEN s.grade_level = 9 THEN sg.final_grade END)) AS freshman,
         ROUND(AVG(CASE WHEN s.grade_level = 10 THEN sg.final_grade END)) AS sophomore,
         ROUND(AVG(CASE WHEN s.grade_level = 11 THEN sg.final_grade END)) AS junior,
         ROUND(AVG(CASE WHEN s.grade_level = 12 THEN sg.final_grade END)) AS senior
FROM 	 student_grades sg INNER JOIN students s
		 ON sg.student_id = s.id
GROUP BY sg.department
ORDER BY sg.department;

-- Assignment 4: Rolling Calculations

-- Visualize tables
SELECT * FROM orders;
SELECT * FROM products;

-- Calculate total sales of each month, cumulative sum and 6 month moving average
WITH sum_sales AS (SELECT 	YEAR(o.order_date) AS yr,
							MONTH(o.order_date) AS mnth,
							SUM(o.units * p.unit_price) AS total_sales
				   FROM 	orders o LEFT JOIN products p
							ON o.product_id = p.product_id
				   GROUP BY yr, mnth)
 
SELECT 	 yr, mnth, total_sales,
		 SUM(total_sales) OVER (ORDER BY yr, mnth) AS cumulative_sum,
         AVG(total_sales) OVER (ORDER BY yr, mnth ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS six_month_ma
FROM 	 sum_sales
ORDER BY yr, mnth;