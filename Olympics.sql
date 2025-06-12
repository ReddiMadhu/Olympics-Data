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
