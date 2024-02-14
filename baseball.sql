-- 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH vandy AS (SELECT
			  DISTINCT playerid,
			  schoolid
			  FROM collegeplaying
			  WHERE schoolid = 'vandy')
SELECT DISTINCT playerid, namefirst AS firstname, namelast AS lastname, COALESCE(SUM(salary), 0) AS total_salary
FROM people
LEFT JOIN vandy
USING(playerid)
LEFT JOIN schools
USING(schoolid)
LEFT JOIN salaries
USING(playerid)
WHERE schoolname = 'Vanderbilt University'
GROUP BY playerid
ORDER BY total_salary DESC;

-- David Price (priceda01) earned the most money with 81,851,296

SELECT DISTINCT playerid, SUM(salary)
FROM salaries
WHERE playerid = 'priceda01'
GROUP BY playerid


-- 2. Using the fielding table, group players into three groups based on their position: label players with position 
-- OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.

SELECT CASE WHEN pos IN ('P', 'C') THEN 'Battery'
	WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	END AS position,
	SUM(po) AS putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position;

-- Battery 41424, Infield 58934, Outfield 29560.


-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the generate_series function 
-- (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: 
-- https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)


SELECT yearid, ROUND(AVG(so), 2)  AS strikeouts, ROUND(AVG(hr), 2)  AS homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY yearid
ORDER BY yearid

WITH bins AS (
    SELECT generate_series(1920, 2010, 10) AS lower,
           generate_series(1930, 2020, 10) AS upper)
-- count values in each bin
SELECT 
	lower, 
	upper, 
	ROUND(SUM(sto.so * 1.0)/SUM(ghome * 1.0), 2) AS avg_strikeouts,  
	ROUND(SUM(sto.hr * 1.0)/SUM(ghome * 1.0), 2) AS avg_homeruns     
-- left join keeps bins
 FROM teams as sto
   LEFT JOIN bins AS b
       ON yearid >= lower
       AND yearid < upper
GROUP BY lower, upper
ORDER BY lower;

--

SELECT yearid / 10 * 10 AS decade,
	ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so, -- G doubles the number of games since there are 2 teams
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1;

-- using GENERATE_SERIES
WITH decade AS (
	SELECT GENERATE_SERIES(1920, 2016, 10) AS start_year,
		GENERATE_SERIES(1929, 2019, 10) AS end_year
)

SELECT start_year AS decade,
ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so, -- G doubles the number of games since there are 2 teams
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
LEFT JOIN decade
	ON yearid BETWEEN start_year AND end_year
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1;

-- 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. 
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

SELECT playerid, namefirst AS firstname, namelast AS lastname, SUM(sb) AS total_sb, 
	SUM(sb + cs) AS total_attempts, ROUND((SUM(sb * 1.0)/SUM(sb + cs)* 1.0)*100, 2) AS percentage
FROM batting
LEFT JOIN people
USING(playerid)
WHERE yearid = 2016
GROUP BY 1, 2, 3
HAVING SUM(sb + cs) >= 20
ORDER BY percentage DESC;

-- Chris Owings had the highest percentage of successful stolen bases in 2016 with 91.3 %.


-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number 
-- of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. 
-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?



-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? 
-- Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, 
-- so be sure that you are counting all stats for each player.

-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year 
-- they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) 
-- Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league 
-- for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- After finishing the above questions, here are some open-ended questions to consider.

-- Open-ended questions

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.

-- 12a. Does there appear to be any correlation between attendance at home games and number of wins?
-- 12b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are 
-- compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?