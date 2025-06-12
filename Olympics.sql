--1 which team has won the maximum gold medals over the years.

SELECT 
    team,
    COUNT(*) AS Count_Gold_Medals
FROM (
    SELECT 
        athletes.team,
        athlete_events.event,
        athlete_events.games
    FROM 
        athlete_events
    JOIN 
        athletes ON athlete_events.athlete_id = athletes.id
    WHERE 
        athlete_events.medal = 'Gold'
    GROUP BY 
        athletes.team, athlete_events.event, athlete_events.games
) AS unique_gold_medals
GROUP BY 
    team
ORDER BY 
    Count_Gold_Medals DESC
LIMIT 1;



#--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
WITH team_year_silver AS (
    SELECT 
        athletes.team AS team,
        ae.year AS year,
        COUNT(*) AS silver_count
    FROM 
        athlete_events ae
    JOIN 
        athletes ON ae.athlete_id = athletes.id
    WHERE 
        ae.medal = 'Silver'
    GROUP BY 
        athletes.team, ae.year
),
ranked_silver_years AS (
    SELECT *,
           RANK() OVER (PARTITION BY team ORDER BY silver_count DESC) AS rnk
    FROM team_year_silver
),
team_total_silver AS (
    SELECT 
        athletes.team AS team, 
        COUNT(*) AS total_silver_medals
    FROM 
        athlete_events ae
    JOIN 
        athletes ON ae.athlete_id = athletes.id
    WHERE 
        ae.medal = 'Silver'
    GROUP BY 
        athletes.team
)
SELECT 
    tts.team,
    tts.total_silver_medals,
    rsy.year AS year_of_max_silver
FROM 
    team_total_silver tts
JOIN 
    ranked_silver_years rsy ON tts.team = rsy.team
WHERE 
    rsy.rnk = 1;

--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years
WITH gold_only_medal AS (
    SELECT DISTINCT athlete_id
    FROM athlete_events
    WHERE medal = 'Gold'
      AND athlete_id NOT IN (
          SELECT DISTINCT athlete_id
          FROM athlete_events
          WHERE medal IN ('Silver', 'Bronze')
      )
)

SELECT athletes.name,
       COUNT(athlete_events.medal) AS gold_medals
FROM athletes
JOIN athlete_events ON athlete_events.athlete_id = athletes.id
WHERE athlete_events.medal = 'Gold'
  AND athlete_events.athlete_id IN (
      SELECT athlete_id FROM gold_only_medal
  )
GROUP BY athletes.name
ORDER BY gold_medals DESC;



#--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
#--and no of golds won in that year . In case of a tie print comma separated player names.

WITH years_gold_medals_names AS (
    SELECT 
        ae.year,
        ath.name,
        COUNT(*) AS gold_medals
    FROM 
        athlete_events ae
    JOIN 
        athletes ath ON ae.athlete_id = ath.id
    WHERE 
        ae.medal = 'Gold'
    GROUP BY 
        ae.year, ath.name
),
max_medals_year AS (
    SELECT 
        year, 
        MAX(gold_medals) AS max_gold
    FROM 
        years_gold_medals_names
    GROUP BY 
        year
),
top_players_each_year AS (
    SELECT 
        ygmn.year,
        ygmn.name,
        ygmn.gold_medals
    FROM 
        years_gold_medals_names ygmn
    JOIN 
        max_medals_year mgy ON ygmn.year = mgy.year AND ygmn.gold_medals = mgy.max_gold
)
SELECT 
    year,
    GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS player_names,
    gold_medals AS golds_won
FROM 
    top_players_each_year
GROUP BY 
    year
ORDER BY 
    year;
