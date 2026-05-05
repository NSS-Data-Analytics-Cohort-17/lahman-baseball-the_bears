--Q1
SELECT MIN(yearid), MAX(yearid)
FROM pitching;

SELECT MIN(yearid), MAX(yearid)
FROM batting;

SELECT * --MIN(yearid), MAX(yearid)
FROM fielding;

SELECT MIN(yearid), MAX(yearid)
FROM appearances;

--Q2
WITH shorty AS (SELECT MIN(height) AS short
				FROM people)
SELECT people.namefirst, 
		people.namelast, 
		people.height, 
		people.playerid
FROM people
CROSS JOIN shorty 
WHERE people.height = shorty.short
GROUP BY namefirst, namelast, height, playerid;
--"Eddie"	"Gaedel"	43	"gaedeed01"

SELECT *
FROM appearances
WHERE playerid = 'gaedeed01';
-- one game in 1951

SELECT teams.yearid, 
		appearances.playerid, 
		teams.teamid
FROM teams
INNER JOIN appearances
	ON appearances.teamid = teams.teamid
	AND appearances.yearid = teams.yearid
WHERE appearances.playerid = 'gaedeed01';
--SLA

--Q3 vandy = schoolid
WITH vandy_players AS 
	(SELECT DISTINCT playerid
	 FROM collegeplaying
	 WHERE schoolid = 'vandy'
	 )
SELECT namefirst, 
		namelast, 
		SUM(salary) AS total_salary, 
		playerid
FROM people
RIGHT JOIN vandy_players USING(playerid)
	--ON vandy_players.playerid = people.playerid
LEFT JOIN salaries USING(playerid)
	--ON vandy_players.playerid = salaries.playerid
GROUP BY playerid, namefirst, namelast
ORDER BY total_salary DESC NULLS LAST;
--"David"	"Price"	81851296	"priceda01"
--wrong, should be like 240M+

--Q4
SELECT SUM(po) AS po_sum,
	CASE
		WHEN pos = 'OF' THEN 'Outfield' 
		WHEN pos IN('SS', '2B', '1B', '3B') THEN 'Infield' 
		WHEN pos IN('P', 'C') THEN 'Battery' 
	END AS pos_group
FROM fielding
WHERE yearid = '2016'
GROUP BY pos_group;

--Q5
SELECT  (yearid / 10) * 10 AS decade, 
		ROUND(SUM(so)::numeric / SUM(g), 2) AS avg_so,
		ROUND(SUM(hr)::numeric / SUM(g), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade DESC NULLS LAST;

--Q5 w/ AVG
SELECT  (yearid / 10) * 10 AS decade, 
		ROUND(AVG(so::numeric / g), 2) AS avg_so,
		ROUND(AVG(hr::numeric / g), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade DESC NULLS LAST;
--answer here

--Q6
SELECT batting.playerid, 
		people.namefirst, 
		people.namelast, 
		ROUND((sb::numeric - cs::numeric) / sb::numeric, 2) AS percent_success_stolen
FROM batting
LEFT JOIN people
	ON batting.playerid = people.playerid
WHERE sb >= 20
	AND yearid = 2016
ORDER BY percent_success_stolen DESC NULLS LAST;
--"Chris"	"Owings"	0.90

--Q7.a
SELECT teamid, 
		name, 
		w, 
		yearid 
FROM teams
WHERE wswin = 'N'
	AND yearid >= 1970
ORDER BY w DESC
LIMIT 1;
--"Seattle Mariners"	116

--Q7.b
SELECT teamid, 
		name, 
		w, 
		yearid 
FROM teams
WHERE wswin = 'Y'
	AND yearid >= 1970
ORDER BY w ASC
LIMIT 1;
--"Los Angeles Dodgers"	63
--season was split in two bc of a players strike

--Q7.b2
SELECT teamid, 
		name, 
		w, 
		yearid 
FROM teams
WHERE wswin = 'Y'
	AND yearid >= 1970
	AND yearid != 1981
ORDER BY w ASC
LIMIT 1;
--"St. Louis Cardinals"	83

--Q7.c
WITH highest_wins AS 
	(SELECT MAX(w) AS most_wins, 
			yearid
		FROM teams
		WHERE yearid >= 1970
		GROUP BY yearid
		ORDER BY yearid DESC)

SELECT COUNT(name)::numeric / (2016-1970) AS percent_wins_with_wswin
FROM teams
LEFT JOIN highest_wins 
	ON highest_wins.yearid = teams.yearid
WHERE teams.yearid >= 1970
	AND w = most_wins
	AND wswin = 'Y';
--12 times since 1970
--26% of the time

--Q8.a Highest Attendance
SELECT team, 
		park_name, 
		ROUND(homegames.attendance::numeric / games, 2) AS avg_att
FROM homegames
LEFT JOIN parks 
	ON homegames.park = parks.park
--RIGHT JOIN teams
	--ON homegames.team = teams.teamid
--LEFT JOIN teamsfranchises
	--ON homegames
WHERE year = 2016
	AND games >= 10
ORDER BY avg_att DESC
LIMIT 5;

--Q8.b Lowest Attendance
SELECT team, 
		park_name, 
		ROUND(attendance::numeric / games, 2) AS avg_att
FROM homegames
LEFT JOIN parks 
	ON homegames.park = parks.park
WHERE year = 2016
	AND games >= 10
ORDER BY avg_att ASC
LIMIT 5;

--Q9
WITH nl_managers AS (
    SELECT *
    FROM awardsmanagers
    WHERE yearid > 1985
      AND awardid ILIKE '%tsn%'
      AND lgid = 'NL'
),
al_managers AS (
    SELECT *
    FROM awardsmanagers
    WHERE yearid > 1985
      AND awardid ILIKE '%tsn%'
      AND lgid = 'AL'
),
both_leagues AS (
    SELECT awardsmanagers.playerid, awardsmanagers.yearid, awardsmanagers.lgid
    FROM nl_managers
    LEFT JOIN awardsmanagers
        ON awardsmanagers.playerid = nl_managers.playerid

    INTERSECT

    SELECT awardsmanagers.playerid, awardsmanagers.yearid, awardsmanagers.lgid
    FROM al_managers
    LEFT JOIN awardsmanagers
        ON awardsmanagers.playerid = al_managers.playerid
)
SELECT people.namefirst, people.namelast, both_leagues.yearid, both_leagues.lgid
FROM both_leagues
INNER JOIN people
	ON both_leagues.playerid = people.playerid;


--Q9.........WORKS BUT NOT INCLUDING PEOPLE TABLE
WITH nl_managers AS (
	SELECT *
	FROM awardsmanagers
	WHERE yearid > 1985
		AND awardid ILIKE '%tsn%'
		AND lgid = 'NL'
),
	al_managers AS (
	SELECT *
	FROM awardsmanagers
	WHERE yearid > 1985
		AND awardid ILIKE '%tsn%'
		AND lgid = 'AL'
	)
(SELECT awardsmanagers.playerid, awardsmanagers.yearid, awardsmanagers.lgid
FROM nl_managers
	LEFT JOIN awardsmanagers
		ON awardsmanagers.playerid = nl_managers.playerid)
INTERSECT
(SELECT awardsmanagers.playerid, awardsmanagers.yearid, awardsmanagers.lgid
FROM al_managers
LEFT JOIN awardsmanagers
		ON awardsmanagers.playerid = al_managers.playerid)

--Q10
WITH career_hr_list AS (
	SELECT playerid, 
			MAX(hr) AS career_high_hr
	FROM batting
	GROUP BY playerid
	),
	years_played AS (
	SELECT playerid,
			COUNT(DISTINCT yearid) AS years_played
	FROM batting
	GROUP BY playerid
	)
SELECT people.namefirst,
		people.namelast,
		batting.hr
FROM batting
LEFT JOIN career_hr_list 
	ON batting.playerid = career_hr_list.playerid
	AND batting.hr = career_hr_list.career_high_hr
LEFT JOIN years_played
	ON batting.playerid = years_played.playerid
LEFT JOIN people
	ON batting.playerid = people.playerid
WHERE career_high_hr >= 1
	AND yearid = 2016
	AND years_played.years_played >= 10
ORDER BY batting.hr DESC;

--Q11 by total salary and total wins per season
WITH team_salary AS (
	SELECT teamid, SUM(salary) AS team_salary, yearid
	FROM salaries
	WHERE yearid >= 2000
	GROUP BY teamid, yearid
	ORDER BY yearid DESC
)

SELECT teams.teamid, teams.w, teams.yearid, team_salary.team_salary
FROM teams
LEFT JOIN team_salary
	ON team_salary.teamid = teams.teamid
	AND team_salary.yearid = teams.yearid
WHERE teams.yearid >= 2000
GROUP BY teams.teamid, teams.yearid, teams.w, team_salary.team_salary
ORDER BY yearid DESC;

--Q11 by avg salary and avg wins per season
WITH team_salary AS (
	SELECT teamid, ROUND(AVG(salary)) AS avg_salary
	FROM salaries
	WHERE yearid >= 2000
	GROUP BY teamid
),
	team_wins AS (
	SELECT teamid, ROUND(AVG(teams.w)) AS avg_wins
	FROM teams
	WHERE yearid >= 2000
	GROUP BY teamid
	)

SELECT teams.teamid, team_wins.avg_wins, team_salary.avg_salary
FROM teams
LEFT JOIN team_salary
	ON team_salary.teamid = teams.teamid
LEFT JOIN team_wins
	ON team_wins.teamid = teams.teamid
WHERE teams.yearid >= 2000
GROUP BY teams.teamid, avg_salary, avg_wins;

--Q12
WITH ghome_attnd AS (
	SELECT team, 
			SUM(games) AS total_games, 
			SUM(attendance) AS total_attnd, 
			year
	FROM homegames
	WHERE year >= 1985
	GROUP BY team, year
	ORDER BY year DESC
)

SELECT ghome, 
		attendance, 
		yearid, 
		w, 
		total_games,
		total_attnd,
		total_attnd - attendance AS attnd_diff
FROM teams
LEFT JOIN ghome_attnd
	ON ghome_attnd.year = teams.yearid
	AND ghome_attnd.team = teams.teamidretro
WHERE yearid >= 1985
ORDER BY yearid DESC;

SELECT *
FROM homegames
WHERE year > 1984
LIMIT 100

SELECT *
FROM teams
WHERE yearid > 2014
--LIMIT 100;