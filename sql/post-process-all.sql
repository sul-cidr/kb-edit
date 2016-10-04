-- 1) ///////////////////////////////////////////////////////////////
-- trag_text
-- re-populate trag_text table, the source for later computation
-- of tragedy index (a 'badge' in bio box)

delete from trag_text;
insert into trag_text(indiv_id,deathtext,eventext)
  SELECT indiv.indiv_id,
  string_agg(DISTINCT COALESCE(event.place_text,' ')||
    COALESCE(event.notes,' ')||COALESCE(event.cause,' ')||
    COALESCE(event.label,' '),' '), -- as deathtext,
  replace(string_agg(DISTINCT COALESCE(event2.place_text,' ')||
    COALESCE(event2.notes,' ')||COALESCE(event2.cause,' ')||
    COALESCE(event2.label,' '),' '),'null','' ) -- as eventext
  FROM indiv
  LEFT JOIN event ON event.indiv_id = indiv.indiv_id AND event.type_ = 'DEAT'
  LEFT JOIN event AS event2 ON event2.indiv_id = indiv.indiv_id
    AND event2.type_ = 'EVEN'
  GROUP BY indiv.indiv_id;
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
  birth_abt = z.year_abt
  from z
  where z.indiv_id = i.indiv_id
  and coalesce(birthyear, birth_abt, best) is null;


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
-- 3a) ///////////////////////////////////////////////////////////////
--    create indiv_dist (distance measures) records for new INDIVs
--    and begin populating

-- remove ghost indiv_dist rows (no public.indiv row)
delete from indiv_dist where indiv_id not in (select indiv_id from indiv);

-- need to add records to indiv_dist for new indiv records
insert into indiv_dist(indiv_id,odnb_id)
  select indiv_id, odnb_id from indiv i
  where i.indiv_id not in (select indiv_id from indiv_dist);

update indiv_dist set odnb = 0 where odnb_id is not null;
-- no nulls allowed, even though we're not computing these
update indiv_dist set centrality = 0 where centrality is null;
update indiv_dist set inbred = 0 where inbred is null;

-- 3b requires extfamily, moved to #6

-- 3c) ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
-- create indiv_dist.odnb_id value for new indivs with odnb_id !!!
update indiv_dist id set odnb_id = i.odnb_id from indiv i
  where i.indiv_id = id.indiv_id and i.odnb_id is not null;
-- get word count for all odnbers
update indiv_dist id set
  odnb_wordcount = o.words
  from odnbers o
  where id.odnb_id is not null
  and o.odnb_id = id.odnb_id;
-- 4) ///////////////////////////////////////////////////////////////
-- indiv_text [ ]
-- remake indiv_text (aggregates event-related verbiage)
-- ?? is occutext the only field used (earlier table has many other fields)

delete from indiv_text;
insert into indiv_text(indiv_id, occutext)
  select e.indiv_id, string_agg(e.label, '. ')
  from event e
  where e.type_ in('OCCU', 'EVEN')
  group by indiv_id;
-- 5) ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id
-- [29937 existing; run 03May2016, 29952]

-- back up indiv_events to the bak schema first
DROP TABLE bak.indiv_events;
select * into bak.indiv_events from indiv_events;
-- remake indiv_events
delete from indiv_events;
insert into indiv_events(indiv_id, particip_array)
  with y as (
  with z as ( select e.recno AS event_id,
      array_accum(p.actor_id) as particip_array
      from event e, particip p where e.recno = p.event_id group by e.recno
      order by event_id )
    select  e.type_ as eventtype, e.label as eventlabel, e.place_text as eventplace,
    period_text as eventdate, e.place_id AS place,
    coalesce(year,year_abt,year_est,-1) as Year,
    case when(year_abt is not null OR year_est is not null) then 'roughly'
         when year > 0 then 'known'
         else ''
    end as accuracy,
    z.particip_array as actor
    from z join event e on z.event_id = e.recno
    )
    select i.indiv_id,
    '['||
    array_to_string(
    array_agg('{"eventtype":"'||y.eventtype||'","eventlabel":"'||y.eventlabel||
      '","eventplace":"'||coalesce(y.eventplace,'')||'","eventdate":"'||coalesce(y.eventdate,'')||
      case when y.place IS null then '"'
           ELSE '","place":'||coalesce(y.place::text,'""')
           end ||
      case when i.birthyear IS null then ''
           ELSE ',"year":'||(y.year-i.birthyear) -- age at event if birth known
           end ||

      ',"accuracy":"'||coalesce(y.accuracy,'')||
      '","actor":'||'["'||array_to_string(y.actor,'","')||'"]}'),',')||
    ']' -- as particip_array
    from indiv i join y on i.indiv_id = any(y.actor)
    group by i.indiv_id order by indiv_id -- limit 300
-- 6) ///////////////////////////////////////////////////////////////
-- create extfamily
-- given current 'indiv', 'event', and 'particip' tables
-- ///////////////////////////////////////////////////////////////
-- uses helper functions:
  -- p_parent(indiv_id,['mother' | 'father'])
  -- p_spouses(indiv_id)
  -- p_children(indiv_id)
  -- p_siblings()
drop table bak.extfamily;
select * into bak.extfamily from extfamily;
delete from extfamily;
-- [run 03May2016, 29952 rows 14+ min.; 01Jun2016 wo/spouse,children, ~14 min]
-- ERROR: null value in column "recno" violates not-null constraint
-- cause: moving/copying table between schemas changed serial sequence to plain integer
-- select * from event where recno is null
insert into extfamily(indiv_id,sex,mother,father,
    birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
  select i.indiv_id, i.sex,
  p_parent(i.indiv_id,'mother'),
  p_parent(i.indiv_id,'father'),
  i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
  from indiv i order by indiv_id;

-- ///////// run helper functions all run 01Jun2016 ////////////////////////
-- spouses
update extfamily set spouses = p_spouses(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- children
update extfamily set children = p_children(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children (all rows)
update extfamily set siblings = p_siblings(indiv_id); -- 3.6 min.

-- (from 3b; extfamily a dependency) /////////////
-- put number of children, marriages into indiv_dist
update indiv_dist id set
  children = coalesce(array_length(ef.children,1),0),
  marriage = coalesce(array_length(ef.spouses,1),0)
  from extfamily ef
  where ef.indiv_id = id.indiv_id;

-- test:
-- select * from extfamily where indiv_id = 'I30349' -- Turing; ok
-- select * from extfamily where indiv_id = 'I30347' -- Turing's father; ok
-- 7) ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [spouseOf, childOf, siblingOf, selfLoop ]
-- [run 03May2016, before: 90270 rows, after: 97914]
drop table bak.edges;
select * into bak.edges from edges;
delete from edges;

-- add selfLoop [run 03May2016, +29952; 01Jun2016]
insert into edges(source,target,relation)
  select i.indiv_id, i.indiv_id, 'selfLoop' from indiv i;
-- spouseOf [run 03May2016, +15191; 01Jun2016]
insert into edges(source,target,relation)
  ( with tbl as (
    select ef.indiv_id as source, unnest(ef.spouses) as target, 'spouseOf' as relation
    from extfamily ef order by source
  ) select a.source, a.target, a.relation from tbl a, tbl b
    WHERE  (a.source, a.target) = (b.target, b.source)
    AND    a.target > a.source
  );
-- childOf [run 03May2016, +34086; 01Jun2016]
insert into edges(source,target,relation)
  ( select ef.indiv_id as source, unnest(children) as target, 'childOf' as relation
  from extfamily ef order by source );
-- siblingOf [run 03May2016, +18685; 01Jun2016]
insert into edges(source,target,relation)
  ( with tbl as (
    select ef.indiv_id as source, unnest(ef.siblings) as target, 'siblingOf' as relation
    from extfamily ef order by source
  ) select a.source, a.target, a.relation from tbl a, tbl b
    WHERE  (a.source, a.target) = (b.target, b.source)
    AND    a.target > a.source
  );

-- some checks
-- select relation, count(*) from bak.edges group by relation order by relation
-- select relation, count(*) from edges group by relation order by relation
-- select count(*) from indiv
-- select source from bak.edges where source not in (select source from edges)
--select distinct(indiv_id) from extfamily
-- 2b) ///////////////////////////////////////////////////////////////
-- recreate tragic table (run time ~14 min)
--  [run 02May2016, 29952 rows; 31May2016, ]
-- "Make sure to set dest = 2017 to dest = 2099 before running this"
-- Array is diedyoung,earlyspouse,earlysibling,earlychild,earlyparent

-- set dest if not dead
-- living INDIVs have a death date of 2017 so timeline bar has end point
-- this needs to get set, reset to 2099 for some reason, then reset
UPDATE indiv SET dest = 2017 WHERE deathyear IS NULL AND death_abt IS NULL
  AND dest IS NULL;

-- now do tragic computation
UPDATE indiv SET dest = 2099 WHERE dest = 2017;

DROP TABLE tragic;

CREATE TABLE tragic AS
  SELECT indiv.indiv_id,
  SUM(
  CASE
  when target.indiv_id IS NULL AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 45  then 1
  else 0
  END
  ) as diedyoung,

  SUM(
  (
  CASE
  when edges.relation = 'spouseOf' AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(target.deathyear,target.death_abt,target.dest) >= 20 then 1
  when edges.relation = 'siblingOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) < COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 12 then 1
  else 0
  END
  )
  ) as total,
  ''||

  SUM(
  (
  CASE
  when edges.relation = 'spouseOf' AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(target.deathyear,target.death_abt,target.dest) >= 20 then 1
  else 0
  END
  )
  )||','||

  SUM(
  (
  CASE
  when edges.relation = 'siblingOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  else 0
  END
  )
  )||','||
  SUM(
  (
  CASE
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  else 0
  END
  )
  )||','||
  SUM(
  (
  CASE
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) < COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 12 then 1
  else 0
  END
  )
  ) as trarray
  FROM indiv
  LEFT JOIN edges ON indiv.indiv_id IN (edges.source, edges.target)
  LEFT JOIN indiv as target ON target.indiv_id IN (edges.source, edges.target) AND target.indiv_ID <> indiv.indiv_id
  GROUP BY indiv.indiv_id;

UPDATE indiv SET dest = 2017 WHERE dest = 2099;
-- 8) ///////////////////////////////////////////////////////////////
--    remake indiv_dist.trarray field

-- 6-16 DONE ALREADY, #3
-- add records to indiv_dist for new indiv records [run 02May2016, added 14 recods]
-- insert into indiv_dist(indiv_id,odnb_id)
--  select indiv_id, odnb from indiv i where i.indiv_id not in
-- (select indiv_id from indiv_dist);

-- then fill in fields for new records
-- insert tragedy and trarray fields in indiv_dist (run time 2.5 sec)
-- test: copy indiv_dist to 'temp' schema, clone it back into 'public' --
-- alter table indiv_dist set schema temp;
-- select * into indiv_dist from temp.indiv_dist;
-- [run 02May2016, seems okay; 01Jun2016]
----------

UPDATE indiv_dist SET trarray =
  '['||(
  CASE
  when LOWER(deathtext) LIKE '%wounds%' OR LOWER(deathtext) LIKE '%battle%' OR LOWER(deathtext) LIKE '%killed in action%' OR LOWER(deathtext) LIKE '%cwgc.org%' then 1
  when LOWER(deathtext) LIKE '%hanged%' OR LOWER(deathtext) LIKE '%shot%' OR LOWER(deathtext) LIKE '%executed%' OR LOWER(deathtext) LIKE '%beheaded%' OR LOWER(deathtext) LIKE '%tower hill%' OR LOWER(deathtext) LIKE '%tyburn%' then 1
  when LOWER(deathtext) LIKE '%murdered%' OR LOWER(deathtext) LIKE '%stabbed%' OR LOWER(deathtext) LIKE '%suicide%' OR LOWER(deathtext) LIKE '%killed herself%' OR LOWER(deathtext) LIKE '%killed himself%' then 1
  else diedyoung
  END
  )||
  ','||tragic.trarray||','||
  (
  CASE
  when LOWER(eventext) LIKE '%insane%' OR LOWER(eventext) LIKE '%breakdown%' OR LOWER(eventext) LIKE '%lunatic%' then 1
  else 0
  END
  )||']',

  tragedy = total +
  (
  CASE
  when LOWER(deathtext) LIKE '%wounds%' OR LOWER(deathtext) LIKE '%battle%' OR LOWER(deathtext) LIKE '%killed in action%' OR LOWER(deathtext) LIKE '%cwgc.org%' then 1
  when LOWER(deathtext) LIKE '%hanged%' OR LOWER(deathtext) LIKE '%shot%' OR LOWER(deathtext) LIKE '%executed%' OR LOWER(deathtext) LIKE '%beheaded%' OR LOWER(deathtext) LIKE '%tower hill%' OR LOWER(deathtext) LIKE '%tyburn%' then 1
  when LOWER(deathtext) LIKE '%murdered%' OR LOWER(deathtext) LIKE '%stabbed%' OR LOWER(deathtext) LIKE '%suicide%' OR LOWER(deathtext) LIKE '%killed herself%' OR LOWER(deathtext) LIKE '%killed himself%' then 1
  else diedyoung
  END
  )
  +
  (
  CASE
  when LOWER(eventext) LIKE '%insane%' OR LOWER(eventext) LIKE '%breakdown%' OR LOWER(eventext) LIKE '%lunatic%' then 1
  else 0
  END
  )

  FROM tragic, trag_text
  WHERE trag_text.indiv_id = tragic.indiv_id
  AND tragic.indiv_id = indiv_dist.indiv_id;


-- 8a) ///////////////////////////////////////////////////////////////
-- requires updated extfamily
-- DONE ALREADY, IN #6
-- put number of children, marriages into indiv_dist
-- update indiv_dist id set
--   children = coalesce(array_length(ef.children,1),0),
--   marriage = coalesce(array_length(ef.spouses,1),0)
--   from extfamily ef
--   where ef.indiv_id = id.indiv_id;

-- 8b) ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- DONE ALREADY, IN #3
-- !!! relies on indiv.odnb value for new indiv records !!!
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
-- update indiv_dist id set
-- --   odnb_id = o.odnb_id,
--   odnb_wordcount = o.words
--   from odnbers o
--   where id.odnb_id is not null
--   and o.odnb_id = id.odnb_id;
-- 9) ///////////////////////////////////////////////////////////////
-- compute indiv_dist.odnb (distance to an ODNBer)
--

select p_odnb();
-- 11) ///////////////////////////////////////////////////////////////
-- put parentless into indiv_dist; > 5 hours !!!!
-- computes max distance to someone with no parent
-- i.e. number of generations by birth in database
select p_parentless();
-- 12) ///////////////////////////////////////////////////////////////
-- populate similarity table with parameters,
-- then p_simmy() computes sims for each INDIV
-- [90 min +/-]

delete from similarity;
insert into similarity(indiv_id,byear,dyear,children,siblings)
  select e.indiv_id, coalesce(i.birthyear,i.birth_abt,i.best),coalesce(i.deathyear,i.death_abt,i.dest),
  coalesce(array_length(children,1),0), coalesce(array_length(siblings,1),0)
  from extfamily e
  join indiv i on e.indiv_id = i.indiv_id;

-- occ 11,019
with z as (
select indiv_id, to_tsvector(array_agg(occu_text)::text) as occ from indiv_occu io
  group by indiv_id
) update similarity s set occ = z.occ from z where s.indiv_id = z.indiv_id;

-- event 11,930
with z as (
select i.indiv_id, to_tsvector(array_agg(e.label)::text) as event from indiv i
  join particip p on i.indiv_id = p.actor_id
  join event e on p.event_id = e.recno
  where e.type_ in ('OCCU','EDUC','EVEN','IMMI','GRAD')
  --and i.indiv_id not in (select indiv_id from similarity)
  group by i.indiv_id
) update similarity s set event = z.event from z where s.indiv_id = z.indiv_id;

-- loc (alternate) 21,762
with z as (
select i.indiv_id, to_tsvector(array_to_string(array_agg(coalesce(pl.admin2,'')||' '||coalesce(pl.admin1,'')||coalesce(pl.ccode,'')),' ')) as loc
  from indiv i
  join particip p on i.indiv_id = p.actor_id
  join event e on p.event_id = e.recno
  join place pl on e.place_id = pl.placeid
  --where i.indiv_id not in (select indiv_id from similarity)
  group by i.indiv_id
) update similarity s set loc = z.loc from z where s.indiv_id = z.indiv_id;

-- 11b) ///////////////////////////////////////////////////////////////
-- create sims.sim_id[] array
-- run 02Jun2016, 86 min.
select p_simmy();

update indiv set marnm = null where marnm = '';
update indiv set search_names = to_tsvector('english', fullname||' '||coalesce(marnm,'') );
