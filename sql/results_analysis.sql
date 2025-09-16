select * from results;

with home_team as(
select home_team as team,
	away_team as opponent,
	home_score as goals_for,
	away_score as goals_against,
	case when home_score > away_score then 1 else 0 end as win,
	case when home_score < away_score then 1 else 0 end as loss,
	case when home_score = away_score then 1 else 0 end as draw
	from results
),

away_team as(
select away_team as team,
	home_team as opponent,
	away_score as goals_for,
	home_score as goals_against,
	case when away_score > home_score then 1 else 0 end as win,
	case when away_score < home_score then 1 else 0 end as loss,
	case when home_score = away_score then 1 else 0 end as draw
	from results
),

all_matches as(
select * from home_team union all select * from away_team
),

team_stats as(
select team,
	count(*) as total_matches,
	sum(win) as total_wins,
	sum(loss) as total_losses,
	sum(goals_for) as total_goals_for, 
	sum(goals_against) as total_goals_against,
	sum(goals_for) - sum(goals_against) as goal_difference,
	round((sum(win) * 100.00) / count(*), 2) as win_percentage
from all_matches
group by team
)

-- All teams stats
select * from team_stats
order by team;

-- Best teams stats
select * from team_stats
where team in (
    select distinct home_team
    from results
    where tournament ilike any 
		(array['%FIFA World Cup%', '%UEFA Euro%', '%Copa America%', '%Olympic Games%'])
    union
    select distinct away_team
    from results
    where tournament ilike any
		(array['%FIFA World Cup%', '%UEFA Euro%', '%Copa America%', '%Olympic Games%'])
)
order by win_percentage desc, goal_difference desc;


-- List all tournaments 
select distinct(tournament) from results
order by tournament;


-- Teams domination in different eras
with all_matches as(
	select home_team as team,
	case when home_score > away_score then 1 else 0 end as win,
	date
	from results
	union all
	select away_team as team,
	case when away_score > home_score then 1 else 0 end as win,
	date
	from results
),

team_decade_stats as(
	select team,
	(extract(year from date)::smallint / 10) * 10 as decade,
	count(*) as total_matches,
	sum(win) as total_wins,
	round((100.00 * sum(win)) / count(*), 2) as win_percentage
	from all_matches
	group by team, decade
	having count(*) > 50
)

select decade, team, total_matches, total_wins, win_percentage
from(
	select *,
	rank() over (partition by decade order by win_percentage desc) as rank
	from team_decade_stats
) ranked
where rank = 1
order by decade;


-- Countries that host the highest number of matches in which they are not participants
select country as host_country, count(*)
from results
where neutral = true and home_team <> country and away_team <>  country
group by country
order by count(*) desc;


-- How much, if at all, does hosting a major tournament help a country's chances in the tournament?
with host_matches as(
	select country as host_country,
	case 
		when home_team = country then home_team
		when away_team = country then away_team
	end as host_team,
	case
		when home_team = country and home_score > away_score then 1
		when away_team = country and away_score > home_score then 1
		else 0
	end as win
	from results
	where tournament ilike any (
	array['FIFA World Cup', '%UEFA%', '%Copa America%'])
)

select host_country,
	count(*) as total_matches,
	sum(win) as total_wins,
	round((100.00 * sum(win)) / count(*), 2) as win_percentage
from host_matches
group by host_country
order by win_percentage desc;