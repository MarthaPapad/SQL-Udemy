-- Final Assignment 
-- Assignment 1: School Analysis

-- Connect to data base
USE maven_advanced_sql;

-- Visualize tables
SELECT * FROM players;
SELECT * FROM salaries;
SELECT * FROM schools;
SELECT * FROM school_details;

-- a) In each decade, how many schools were there that produced MLB players?
SELECT 	 FLOOR(yearID / 10) * 10 AS decate,
         COUNT(DISTINCT schoolID) AS num_schools
FROM 	 schools
GROUP BY decate
ORDER BY decate;

-- b) What are the names of the top 5 schools that produced the most players
WITH cal_rank AS (SELECT   sd.name_full,
						   COUNT(DISTINCT s.playerID) AS num_players,
						   DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT s.playerID) DESC) AS pl_rank
				  FROM 	   schools s LEFT JOIN school_details sd
						   ON s.schoolID = sd.schoolID
				  GROUP BY s.schoolID)

SELECT 	 name_full AS top_5_schools, num_players
FROM 	 cal_rank
WHERE 	 pl_rank <= 5
ORDER BY pl_rank;

-- c) For each decade, what were the names of the top 3 schools that produced the most players?
WITH cal_decate AS (SELECT 	schoolID, yearID, playerID,
							FLOOR(yearID / 10) * 10 AS decate
					FROM 	schools),
                  
	 cal_rank AS (SELECT   sd.name_full, s.decate,
						   COUNT(DISTINCT s.playerID) AS num_players,
						   ROW_NUMBER() OVER (PARTITION BY s.decate ORDER BY COUNT(DISTINCT s.playerID) DESC) AS pl_rank
				  FROM 	   cal_decate s LEFT JOIN school_details sd
						   ON s.schoolID = sd.schoolID
				  GROUP BY sd.name_full, s.decate)

SELECT	 decate, name_full, num_players
FROM 	 cal_rank
WHERE	 pl_rank <= 3
ORDER BY decate, pl_rank;


-- Assignment 2: Salary Analysis

-- a) Return the top 20% of teams in terms of average annual spending
WITH cal_av_sal AS (SELECT 	 teamID, yearID, SUM(salary) AS annual_spending
					FROM 	 salaries
					GROUP BY teamID, yearID),

	 cal_top_20 AS (SELECT 	 teamID, AVG(annual_spending) AS av_spending,
							 NTILE(5) OVER (ORDER BY AVG(annual_spending) DESC) AS top_20
					FROM 	 cal_av_sal
					GROUP BY teamID)
             
SELECT	teamID, ROUND(av_spending / 1000000, 1) AS av_spend_millions
FROM 	cal_top_20
WHERE 	top_20 = 1;

-- b) For each team, show the cumulative sum of spending over the years
WITH cal_csum AS (SELECT   yearID, teamID, SUM(salary) AS sum_spending
				  FROM 	   salaries
				  GROUP BY yearID, teamID)

SELECT 	 teamID, yearID,
		 ROUND(SUM(sum_spending) OVER (PARTITION BY teamID ORDER BY yearID) / 1000000, 1)
         AS cumul_sum
FROM 	 cal_csum
ORDER BY teamID, yearID;

-- c) Return the first year that each team's cumulative spending surpassed 1 billion
WITH cal_sum AS (SELECT   yearID, teamID, SUM(salary) AS sum_spending
				 FROM 	  salaries
				 GROUP BY yearID, teamID),

	 cal_cusum AS (SELECT	yearID, teamID, sum_spending,
							SUM(sum_spending) OVER (PARTITION BY teamID ORDER BY yearID) 
							AS cumul_sum
					 FROM 	cal_sum),
                  
	 first_b AS (SELECT yearID, teamID, cumul_sum,
						ROW_NUMBER() OVER (PARTITION BY teamID ORDER BY cumul_sum) AS fb
				 FROM	cal_cusum
				 WHERE 	cumul_sum > 1000000000)

SELECT 	 teamID, yearID AS first_bil,
		 ROUND(cumul_sum / 1000000000, 2) AS bil
FROM 	 first_b
WHERE 	 fb = 1
ORDER BY teamID;


-- Assignment 3: Player Career Analysis

-- a) For  each player, calculate their age at their first (debut) game, their last game,
-- and their career length (all in years). Sort from longest career to shortest career.
WITH make_birthdate AS (SELECT 	nameGiven,
								MAKEDATE(birthYear, 1) + INTERVAL (birthMonth - 1) MONTH + INTERVAL (birthDay - 1) DAY
								AS birthdate,
								debut, finalGame
					    FROM 	players)
                       
SELECT 	 nameGiven,
		 TIMESTAMPDIFF(YEAR, birthdate, debut) AS debut_age,
         TIMESTAMPDIFF(YEAR, birthdate, finalGame) AS last_game_age,
         TIMESTAMPDIFF(YEAR, debut, finalGame) AS career_length
FROM 	 make_birthdate
ORDER BY career_length DESC;

-- b) What team did each player play on for their starting and ending years?
WITH cal_debut AS (SELECT 	p.playerID, nameGiven,
							s.teamID AS debut_team,
							YEAR(p.debut) AS debut_year
					FROM 	players p INNER JOIN salaries s
							ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID),

	 cal_final AS (SELECT	p.playerID, nameGiven,
							s.teamID AS final_team,
							YEAR(p.finalGame) AS final_year
				   FROM 	players p INNER JOIN salaries s
							ON p.playerID = s.playerID AND YEAR(p.finalGame) = s.yearID)
	
SELECT	cd.nameGiven, cd.debut_year, cd.debut_team, cf.final_year, cf.final_team
FROM	cal_debut cd INNER JOIN cal_final cf
		ON cd.playerID = cf.playerID;

-- c) How many players started and ended on the same team and also played for over a decade?
WITH cal_debut AS (SELECT 	p.playerID, p.nameGiven,
							s.teamID AS debut_team,
							YEAR(p.debut) AS debut_year
				   FROM 	players p INNER JOIN salaries s
							ON p.playerID = s.playerID AND YEAR(p.debut) = s.yearID),

	 cal_final AS (SELECT	p.playerID, p.nameGiven,
							s.teamID AS final_team,
							YEAR(p.finalGame) AS final_year
				   FROM 	players p INNER JOIN salaries s
							ON p.playerID = s.playerID AND YEAR(p.finalGame) = s.yearID)
	
SELECT	cd.nameGiven, cd.debut_year, cd.debut_team, cf.final_year, cf.final_team
FROM	cal_debut cd INNER JOIN cal_final cf
		ON cd.playerID = cf.playerID
WHERE 	cd.debut_team = cf.final_team AND cf.final_year - cd.debut_year > 10;


-- Assignment 4: Player Comparison Analysis

-- a) Which players have the same birthday?
WITH birthdate_list AS (SELECT 	 MAKEDATE(birthYear, 1) + INTERVAL (birthMonth - 1) MONTH + INTERVAL (birthDay - 1) DAY AS birthdate,
								 GROUP_CONCAT(nameGiven SEPARATOR ", ") AS pl_birthday
						FROM 	 players
						WHERE 	 birthYear AND birthMonth AND birthDay IS NOT NULL
						GROUP BY birthYear, birthMonth, birthDay
						ORDER BY birthYear, birthMonth, birthDay)

SELECT	*
FROM 	birthdate_list
WHERE 	pl_birthday LIKE "%, %";

-- b) Create a summary table that shows for each team, what percent of players bat right,
-- left and both.
WITH cal_rlb AS (SELECT	  s.teamID,
						  SUM(CASE WHEN p.bats = "R" THEN 1 ELSE 0 END) AS right_bat,
						  SUM(CASE WHEN p.bats = "L" THEN 1 ELSE 0 END) AS left_bat,
						  SUM(CASE WHEN p.bats = "B" THEN 1 ELSE 0 END) AS both_bat
				 FROM	  salaries s LEFT JOIN players p
						  ON s.playerID = p.playerID
				 GROUP BY s.teamID)

SELECT 	 teamID,
		 ROUND(right_bat / (right_bat + left_bat + both_bat) * 100, 2) AS right_bat_pct,
         ROUND(left_bat / (right_bat + left_bat + both_bat) * 100, 2) AS left_bat_pct,
         ROUND(both_bat / (right_bat + left_bat + both_bat) * 100, 2) AS both_bat_pct
FROM	 cal_rlb
ORDER BY teamID;

-- c) How have average height and weight at debut game changed over the years, and
-- what's the decade-over-decade difference?
SELECT 	 YEAR(debut) AS year_debut,
		 ROUND(AVG(height), 2) AS av_height,
         ROUND(AVG(weight), 2) AS av_weight
FROM 	 players
WHERE 	 YEAR(debut) IS NOT NULL
GROUP BY year_debut
ORDER BY year_debut;

       
WITH cal_dec_average AS (SELECT	  FLOOR(YEAR(debut) / 10) * 10 AS decate,
								  ROUND(AVG(height), 2) AS av_height,
								  ROUND(AVG(weight), 2) AS av_weight
						 FROM 	  players
						 WHERE 	  YEAR(debut) IS NOT NULL
						 GROUP BY decate)

SELECT	decate,
		av_height,
		av_height - LAG(av_height) OVER (ORDER BY decate) AS av_height_diff,
        av_weight,
        av_weight - LAG(av_weight) OVER (ORDER BY decate) AS av_weight_diff
FROM 	cal_dec_average;