drop table if exists results;

create table results(
date date,
home_team text,
away_team text,
home_score smallint,
away_score smallint,
tournament text,
city text,
country text,
neutral text
);

copy results
from 'D:\Projects\International_Football_Matches_Analysis\data\results.csv'
with (format csv, header true);

alter table results
alter column neutral type boolean
using neutral::boolean;

select * from results;

