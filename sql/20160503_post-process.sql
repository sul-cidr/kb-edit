-- generating indiv_dist and related (tragedy index)

-- 1) ///////////////////////////////////////////////////////////////
-- trag_text [run 03May2016, 29952 rows; 31 May 29951 rows]
delete from trag_text;
insert into trag_text(indiv_id,deathtext,eventext)
	SELECT indiv.indiv_id,
	string_agg(DISTINCT COALESCE(event.place_text,' ')||COALESCE(event.notes,' ')||COALESCE(event.cause,' ')||
		COALESCE(event.label,' '),' '), -- as deathtext,
	replace(string_agg(DISTINCT COALESCE(event2.place_text,' ')||COALESCE(event2.notes,' ')||COALESCE(event2.cause,' ')||
			COALESCE(event2.label,' '),' '),'null','' ) -- as eventext
	FROM indiv
	LEFT JOIN event ON event.indiv_id = indiv.indiv_id AND event.type_ = 'DEAT'
	LEFT JOIN event AS event2 ON event2.indiv_id = indiv.indiv_id AND event2.type_ = 'EVEN'
	GROUP BY indiv.indiv_id;

-- 2) ///////////////////////////////////////////////////////////////
-- tragic (run time ~14 min) [run 02May2016, 29952 rows; 31May2016, ]
-- "Make sure to set dest = 2013 to dest = 2099 before running this"
-- Array is diedyoung,earlyspouse,earlysibling,earlychild,earlyparent

UPDATE indiv SET dest = 2099 WHERE dest = 2013;

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

UPDATE indiv SET dest = 2013 WHERE dest = 2099;
-- new people for whom we have no death year
update indiv set dest = 2013 where deathyear is null and death_abt is null and dest is null;

-- 3) ///////////////////////////////////////////////////////////////
-- remove ghost indiv_dist rows (no public.indiv row)
delete from indiv_dist where indiv_id not in (select indiv_id from indiv);
-- need to add records to indiv_dist for new indiv records
insert into indiv_dist(indiv_id,odnb_id)
	select indiv_id, odnb from indiv i where i.indiv_id not in (select indiv_id from indiv_dist);
-- none at the moment

-- then fill in fields for new records
-- insert tragedy and trarray fields in indiv_dist (run time 2.5 sec)
-- test: copy indiv_dist to 'temp' schema, clone it back into 'public' --
-- alter table indiv_dist set schema temp;
-- select * into indiv_dist from temp.indiv_dist;

-- 3a) ///////////////////////////////////////////////////////////////
UPDATE indiv_dist
SET trarray =
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


-- 3b) ///////////////////////////////////////////////////////////////
-- put number of children, marriages into indiv_dist
update indiv_dist id set 
  children = coalesce(array_length(ef.children,1),0),
  marriage = coalesce(array_length(ef.spouses,1),0)
  from extfamily ef
	where ef.indiv_id = id.indiv_id;

-- 3c) ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
-- create indiv_dist.odnb_id value for new indivs with odnb_id !!!
update indiv_dist id set odnb_id = i.odnb_id from indiv i where i.indiv_id = id.indiv_id and i.odnb_id is not null;
-- get word count for all odnbers
update indiv_dist id set 
  odnb_wordcount = o.words
  from odnbers o
	where id.odnb_id is not null
	and o.odnb_id = id.odnb_id;



-- indiv_text, indiv_events, extfamily, edges
-- 4) ///////////////////////////////////////////////////////////////
-- indiv_text [run 03May2016, 11555 rows; 31May2016, 11555 rows]
-- ?? is occutext the only field used (earlier table has many other fields)
delete from indiv_text;
insert into indiv_text(indiv_id, occutext)
	select e.indiv_id, string_agg(e.label, '. ')
	from event e
	where e.type_ in('OCCU', 'EVEN')
	group by indiv_id;
--------------------------------------------------------------------

-- 5) ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id
-- [29937 existing; run 03May2016, 29952] <- 15 new records but only 14 new INDIVs
DROP table bak.indiv_events;
select * into bak.indiv_events from indiv_events;
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
-- uses helpers:
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
select * from event where recno is null
insert into extfamily(indiv_id,sex,mother,father,-- spouses,children, -- siblings,
		birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
	select i.indiv_id, i.sex, 
	p_parent(i.indiv_id,'mother'), 
	p_parent(i.indiv_id,'father'),
--	p_spouses(indiv_id),
-- p_children(indiv_id),
-- p_siblings(indiv_id), -- depends on children 
	i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
	from indiv i order by indiv_id; -- limit 120;

-- ///////// run helper functions all run 01Jun2016 ////////////////////////
-- spouses
update extfamily set spouses = p_spouses(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- children
update extfamily set children = p_children(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children (all rows)
update extfamily set siblings = p_siblings(indiv_id); -- 3.6 min.
-- test: seems ok
select * from extfamily where indiv_id = 'I30349' -- Turing; ok
select * from extfamily where indiv_id = 'I30347' -- Turing's father; ok


-- 8) ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [spouseOf, childOf, siblingOf, selfLoop ]
-- [run 03May2016, before: 90270 rows, after: 97914]
drop table bak.edges;
select * into bak.edges from edges;
delete from edges;

-- selfLoop [run 03May2016, +29952; 01Jun2016]
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
select relation, count(*) from bak.edges group by relation order by relation
select relation, count(*) from edges group by relation order by relation
select count(*) from indiv
select source from bak.edges where source not in (select source from edges)
--select distinct(indiv_id) from extfamily

-- 9) ///////////////////////////////////////////////////////////////
-- add records to indiv_dist for new indiv records [run 02May2016, added 14 recods]
-- 01Jun2016: no result b/c no new individuals at this time
insert into indiv_dist(indiv_id,odnb_id)
	select indiv_id, odnb from indiv i where i.indiv_id not in (select indiv_id from indiv_dist) -- order by indiv_id

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

    	
-- 9c) ///////////////////////////////////////////////////////////////
-- requires updated extfamily
-- put number of children, marriages into indiv_dist
update indiv_dist id set 
  children = coalesce(array_length(ef.children,1),0),
  marriage = coalesce(array_length(ef.spouses,1),0)
  from extfamily ef
	where ef.indiv_id = id.indiv_id;

-- 9d) ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- !!! relies on indiv.odnb value for new indiv records !!!
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
update indiv_dist id set 
--   odnb_id = o.odnb_id,
  odnb_wordcount = o.words
  from odnbers o
	where id.odnb_id is not null
	and o.odnb_id = id.odnb_id;

-- ONE TIME: update existing master with odnb id (3627 updated)
-- update indiv i set odnb_id = id.odnb_id from indiv_dist id
-- 	where i.indiv_id = id.indiv_id 
-- 	and id.odnb_id is not null


-- ***** confirm these aren't using 'test_' tables and dependencies met

-- 10) ///////////////////////////////////////////////////////////////
-- put odnb (distance) into indiv_dist
-- 3627 odnbers at the moment
-- 01Jun2016, 
select p_odnb();

-- 11) ///////////////////////////////////////////////////////////////
-- put parentless into indiv_dist
select p_parentless();

-- 12) ///////////////////////////////////////////////////////////////
-- similarity, then sims
-- 12a) occ, event, loc text ////////////////////////////////////////

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

-- 12b) ///////////////////////////////////////////////////////////////
-- create sims.sim_id[] array
select p_simmy();


-- (???) cleanup
update indiv set marnm = null where marnm = ''
update indiv set search_names = to_tsvector('english', coalesce(marnm,fullname))


