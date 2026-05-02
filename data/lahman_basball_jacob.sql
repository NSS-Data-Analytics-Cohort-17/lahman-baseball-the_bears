--#1

SELECT MAX(yearid), MIN(yearid)
FROM batting;

------------------------------------------------------------------------------------------
--#2

SELECT 
    height AS height_feet,appearances.yearid,
    namefirst,
    namelast,
    team_names.name,
    people.playerid,
    COUNT(appearances.playerid) AS games_played
FROM people
    INNER JOIN appearances USING(playerid)
    INNER JOIN (
        		SELECT DISTINCT teamid, yearid, name 
        		FROM teams) 
				AS team_names USING(teamid,yearid)                   	 		 
WHERE height IS NOT NULL AND people.playerid = 'gaedeed01'
GROUP BY height, namefirst, namelast, team_names.name, people.playerid,appearances.yearid
ORDER BY height_feet ASC;
------------------------------------------------------------------------------------------
--#3

SELECT namegiven,people.playerid, SUM(salary)::NUMERIC::MONEY AS Salary
FROM people
    INNER JOIN (
        SELECT playerid, schoolid 
        FROM collegeplaying
    ) AS cp USING(playerid)
    INNER JOIN schools USING(schoolid)
	INNER JOIN salaries USING(playerid)
WHERE schools.schoolname = 'Vanderbilt University'
GROUP BY people.playerid
ORDER BY salary DESC;
------------------------------------------------------------------------------------------
--#4
SELECT CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN('1B','2B','3B','SS') THEN 'Infield'
		WHEN pos IN('P','C') THEN 'Battery' ELSE POS END AS group_players,
		SUM(po) AS Number_of_Putouts
FROM fielding
GROUP BY group_players
ORDER BY Number_of_Putouts



------------------------------------------------------------------------------------------
--#5 Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--			Do the same for home runs per game. Do you see any trends?
WITH so_hr_decade as (SELECT (yearid/10) * 10 AS decade,ROUND(SUM(SO)::numeric/(SUM(g)),2) AS avg_so, ROUND(SUM(hr)::numeric/(SUM(g)),2) AS avg_hr
						FROM teams
						GROUP by decade)
SELECT *
FROM so_hr_decade
WHERE decade >= 1920 AND avg_so IS NOT NULL
ORDER BY decade DESC;

--- Strikes outs nearly tripled HR near the 2000's, doing some reaserch this was dubbed the 'Steriod Era', AVG 'SO' increases too due to pitchers catching up but also because 

-- Batters tend to go for full home runs (Full strength bat swing & extreme angles) naturally dropping accuracy. This is also known as the 'Three True Outcomes' 
-----------------------------------------------------------------------------------------------------------------------

--#6 Find the player who had the most success stealing bases in 2016, 
--where __success__ is measured as the percentage of stolen base attempts which are successful.
--(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

--BATTING : SB = Stolen Bases, CS = Caught Stealing
---- BY PLAYER, Highest '__success__' = SB/CS+SB


	WITH success_rate AS (
					SELECT playerID,ROUND(SUM(COALESCE(sb,0))::numeric / SUM(COALESCE(sb,0) + COALESCE(cs,0))::numeric, 3) AS __success__
					FROM batting
					WHERE yearid = 2016
					GROUP BY playerID
					HAVING SUM(COALESCE(sb,0) + COALESCE(cs,0)) >= 20
				ORDER BY __success__ DESC)
SELECT playerid,namegiven,__success__
FROM Success_rate 
	INNER JOIN people USING(playerid)
ORDER BY __success__ DESC;
-----------------------------------------------------------------------------------------------------------------------
--#7
--From 1970 – 2016
--largest number of wins for a team that ** did not win the world series **
-- What is the smallest number of wins for a team that did win the world series

--7a
SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'N'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name,yearid
ORDER BY total_wins DESC


--7b
SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name,yearid
ORDER BY total_wins ASC

--7c

SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1982 AND 2016
GROUP BY name,yearid
ORDER BY total_wins ASC

--50-day players' strike
--------------------------------------------------------------------------
-- #8
--	Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016
-- Attendance BY TEAM & PARK & PER GAME,
--	2016
-- SELECT park name, team name, and average attendance
-- PARK THRESHOLD = 10 GAMES
-- LIMIT TOP 5 and 
	
WITH main AS (SELECT park_name,AVG(attendance/games) AS avg_attendance,year,
				team
		FROM homegames
			INNER JOIN parks USING(park)
		WHERE games>=10
		GROUP BY park_name,team,year
		ORDER BY avg_attendance DESC)
SELECT main.avg_attendance,teams.name AS teams_name,park_name,yearid
FROM main
	INNER JOIN teams ON main.team = teams.teamid AND main.year = teams.yearid
WHERE yearid >=2016
ORDER BY avg_attendance DESC

------------------------------------------------------------------------------------------------------

--#9
---Which managers have won the TSN Manager of the Year award 
--in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award

WITH Names_of_winners AS (SELECT namefirst,namelast,playerid,yearid ---Need year ID bc they only won it that year
FROM people
	INNER JOIN (SELECT playerid,awardid, yearid
			FROM awardsmanagers
			WHERE awardid ILIKE '%TSN Manager of the Year%' AND playerid IN (
              SELECT playerid FROM awardsmanagers WHERE lgid = 'AL' AND awardid ILIKE '%TSN Manager of the Year%'
              INTERSECT
              SELECT playerid FROM awardsmanagers WHERE lgid = 'NL' AND awardid ILIKE '%TSN Manager of the Year%')
			  )
			  AS tsn_award_al_nl USING(playerid))
SELECT DISTINCT namefirst, --I added distinct so we can stop seeing duplicates
		namelast,
		teams.name as Teams_managed
FROM Names_of_winners
	INNER JOIN managers USING(playerid,yearid)
			INNER JOIN teams USING(teamid,yearid)
ORDER BY namefirst DESC;


--------------------------------------------------------------------------
---#10
WITH career_total AS (SELECT 
        playerid, 
        MAX(hr) AS career_high_hr,
        COUNT(DISTINCT yearid) AS years_played
    FROM batting
    GROUP BY playerid)
SELECT 
	people.namegiven,
	batting.hr AS HR_2016,playerid
FROM batting
	INNER JOIN people
		USING(playerid)
	INNER JOIN career_total USING(playerid)
WHERE batting.yearid = 2016
	AND batting.hr >=1
	AND career_total.years_played >= 10
	AND batting.hr = career_total.career_high_hr
ORDER BY hr_2016 DESC
  --- OR --- (MORE NUANCED)
WITH career_stats AS (
	SELECT playerid, yearid,
			SUM(hr) AS total_hr_for_season
	FROM batting
	GROUP BY playerid,yearid
	ORDER BY playerid --- every player give every year they played.
),
career_summaries AS (
	SELECT
		Playerid,
		MAX(total_hr_for_season) AS Career_high_hr,
		COUNT(yearid) AS total_years_played
	FROM career_stats
	GROUP BY playerid)
SELECT
	people.namegiven,
	people.namefirst,
	people.namelast,
	career_stats.total_hr_for_season AS HR_2016
FROM career_stats
	INNER JOIN people USING(playerid)
	INNER JOIN career_summaries USING(playerid)
WHERE career_stats.yearid = 2016
	AND career_stats.total_hr_for_season >= 1
	AND career_summaries.total_years_played >= 10
	AND career_stats.total_hr_for_season = career_summaries.Career_high_hr
ORDER BY hr_2016 DESC 

--------------------------------------------------------------------------

--#11

SELECT *
FROM teams
	INNER JOIN salaries USING(teamid)
WHERE YEARid >= 2000;

