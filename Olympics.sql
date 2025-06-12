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


#--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
#--print 3 columns medal,year,sport
WITH medal_ranked_data AS (
    SELECT 
        ae.medal,
        ae.year,
        ae.sport,
        RANK() OVER (
            PARTITION BY ae.medal 
            ORDER BY ae.year
        ) AS ranker
    FROM athlete_events ae
    JOIN athletes a ON ae.athlete_id = a.id
    WHERE a.team = 'India' 
      AND ae.medal IS NOT NULL
)

SELECT DISTINCT 
    medal, 
    year, 
    sport
FROM medal_ranked_data
WHERE ranker = 1;



#--6 find players who won gold medal in summer and winter olympics both.
SELECT DISTINCT 
    ath.name
FROM athlete_events ae
JOIN athletes ath ON ae.athlete_id = ath.id
WHERE ae.medal = 'Gold'
  AND ae.season = 'Summer'
  AND ae.athlete_id IN (
      SELECT ae2.athlete_id
      FROM athlete_events ae2
      WHERE ae2.medal = 'Gold'
        AND ae2.season = 'Winter'
  );




#--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
SELECT DISTINCT g.name, g.year
FROM 
    (SELECT a.id, a.name, ae.year
     FROM athletes a
     JOIN athlete_events ae ON ae.athlete_id = a.id
     WHERE ae.medal = 'Gold') g
JOIN 
    (SELECT a.id, a.name, ae.year
     FROM athletes a
     JOIN athlete_events ae ON ae.athlete_id = a.id
     WHERE ae.medal = 'Silver') s
  ON g.id = s.id AND g.year = s.year
JOIN 
    (SELECT a.id, a.name, ae.year
     FROM athletes a
     JOIN athlete_events ae ON ae.athlete_id = a.id
     WHERE ae.medal = 'Bronze') b
  ON g.id = b.id AND g.year = b.year;
/*
SELECT 
    a.name,
    ae.year
FROM 
    athletes a
JOIN 
    athlete_events ae ON ae.athlete_id = a.id
WHERE 
    ae.medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY 
    a.name, ae.year
HAVING 
    COUNT(DISTINCT CASE WHEN ae.medal = 'Gold' THEN 1 END) > 0 AND
    COUNT(DISTINCT CASE WHEN ae.medal = 'Silver' THEN 1 END) > 0 AND
    COUNT(DISTINCT CASE WHEN ae.medal = 'Bronze' THEN 1 END) > 0;
*/



#--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
#--Assume summer olympics happens every 4 year starting 2000. print player name and event name.
WITH gold_wins AS (
  SELECT
    ae.athlete_id,
    ath.name,
    ae.event,
    ae.year
  FROM athlete_events ae
  JOIN athletes ath 
    ON ae.athlete_id = ath.id
  WHERE 
    ae.medal  = 'Gold'
    AND ae.season = 'Summer'
    AND ae.year >= 2000
),
sequenced AS (
  SELECT
    athlete_id,
    name,
    event,
    year,
    LEAD(year, 1) OVER (PARTITION BY athlete_id, event ORDER BY year) AS next_year,
    LEAD(year, 2) OVER (PARTITION BY athlete_id, event ORDER BY year) AS next2_year
  FROM gold_wins
)
SELECT DISTINCT
  name,
  event
FROM sequenced
WHERE 
  next_year  = year + 4
  AND next2_year = year + 8
ORDER BY name, event;
