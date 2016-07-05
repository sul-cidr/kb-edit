-- 11) ///////////////////////////////////////////////////////////////
-- similarity, then sims
-- 11a) occ, event, loc text ////////////////////////////////////////

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
