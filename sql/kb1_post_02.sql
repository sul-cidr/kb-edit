-- 2) ///////////////////////////////////////////////////////////////
--  birth and death dates/years are drawn from multiple (repetitive) locations
--  this aligns them

-- update event.period_text where exact date is known
update event set period_text = to_char(event_date, 'YYYY Month DD')
  where event_date is not null;

-- update event.place_text to be null if empty
update event set place_text = null where place_text = '';

-- copy birth year data for new indivs from events
-- (no birth data in indiv)
with z as (
select i.indiv_id, p.event_id, e.year, e.year_abt, e.year_est from indiv i
   join particip p on i.indiv_id = p.actor_id
   join event e on p.event_id = e.recno
   where p.role = 'child'
) update indiv i set
  birthyear = z.year,
  birth_abt = z.year_abt,
--  best = z.year_est from z
  where z.indiv_id = i.indiv_id
  and birthyear is null and birth_abt is null; --and best is null;


-- and death data
with z as (
select i.indiv_id, p.event_id, e.year, e.year_abt, e.year_est from indiv i
   join particip p on i.indiv_id = p.actor_id
   join event e on p.event_id = e.recno
   where p.role = 'deceased'
) update indiv i set
  deathyear = z.year,
  death_abt = z.year_abt,
  dest = z.year_est from z
  where z.indiv_id = i.indiv_id
  and deathyear is null and death_abt is null and dest is null;
