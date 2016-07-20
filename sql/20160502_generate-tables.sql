-- post-updates sql to generate kb1 tables
-- update indiv
-- indiv_text, indiv_events, extfamily, edges

-- ///////////////////////////////////////////////////////////////
-- update indiv birth and death years from events
-- select * from indiv where birthyear is null and birth_abt is null and best is null -- none, everyone gets at least one
with z as (
select p.event_id, p.actor_id, e.type_, e.year, e.year_abt, e.year_est from particip p
	join indiv i on p.actor_id = i.indiv_id
	join event e on p.event_id = e.recno
	where p.actor_id in (select indiv_id from indiv where recno > 229348)
	and e.type_ = 'BIRT'
 )
update indiv i set
	birthyear = z.year,
	birth_abt = z.year_abt,
	best = z.year_est
	from z where i.indiv_id = z.actor_id;
-- now DEAT
with z as (
select p.event_id, p.actor_id, e.type_, e.year, e.year_abt, e.year_est from particip p
	join indiv i on p.actor_id = i.indiv_id
	join event e on p.event_id = e.recno
	where p.actor_id in (select indiv_id from indiv where recno > 229348)
	and e.type_ = 'DEAT'
 )
update indiv i set
	deathyear = z.year,
	death_abt = z.year_abt,
	dest = z.year_est
	from z where i.indiv_id = z.actor_id;
-- give living people a death estimate, 75 years old
with z as (
select indiv_id, coalesce(birthyear,birth_abt,best) as byear from indiv where deathyear is null and death_abt is null and dest is null
) update indiv i set dest = z.byear+75 from z where z.indiv_id = i.indiv_id;

-- ///////////////////////////////////////////////////////////////
-- indiv_text [run 03May2016, 11555 rows]
-- ?? is occutext the only field used (earlier table has many other fields)
delete from indiv_text;
insert into indiv_text(indiv_id, occutext)
	select e.indiv_id, string_agg(e.label, '. ')
	from event e
	where e.type_ in('OCCU', 'EVEN')
	group by indiv_id;
--------------------------------------------------------------------

-- ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id
-- [29937 existing; run 03May2016, 29952] <- 15 new records but only 14 new INDIVs
delete from test_indivevents;
insert into test_indivevents(indiv_id, particip_array)
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
		z.particip_array as actors
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
			'","actor":'||'["'||array_to_string(y.actors,'","')||'"]}'),',')||
		']' -- as particip_array
		-- into test_indivevents
		from indiv i join y on i.indiv_id = any(y.actors)
		where i.indiv_id = 'I1'
-- 		where i.indiv_id in ('I30336','I30337','I30338','I30339','I30340','I30341','I30342','I30343','I30344','I30345','I30346','I30347','I30348','I30349')
		group by i.indiv_id order by indiv_id --limit 300


-- ///////////////////////////////////////////////////////////////
-- create extfamily
-- given current 'indiv', 'event', and 'particip' tables
-- ///////////////////////////////////////////////////////////////
-- uses helpers:
	-- p_parent(indiv_id,['mother' | 'father'])
	-- p_spouses(indiv_id)
	-- p_children(indiv_id)
	-- p_siblings()

delete from test_extfamily;
-- [run 03May2016, 29952 rows 14+ min.]
insert into test_extfamily(indiv_id,sex,mother,father, --spouses,children,siblings,
		birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
	select i.indiv_id, i.sex,
	p_parent(i.indiv_id,'mother'),
	p_parent(i.indiv_id,'father'),
 	p_spouses(indiv_id),
  	p_children(indiv_id),
	i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
	from indiv i order by indiv_id; -- limit 120;

-- ///////// run helper functions ////////////////////////
-- spouses
-- update test_extfamily set spouses = p_spouses(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- children
-- update test_extfamily set children = p_children(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children (all rows)
update test_extfamily set siblings = p_siblings(indiv_id); -- 3.6 min.
-- test: seems ok
select * from test_extfamily where indiv_id = 'I30349' -- Turing; ok
select * from test_extfamily where indiv_id = 'I30347' -- Turing's father; ok


-- ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [spouseOf, childOf, siblingOf, selfLoop ]
-- [run 03May2016, before: 90270 rows, after: 97914]

delete from test_edges;

-- selfLoop [run 03May2016, +29952]
insert into test_edges(source,target,relation)
	select i.indiv_id, i.indiv_id, 'selfLoop' from indiv i;
-- spouseOf [run 03May2016, +15191]
insert into test_edges(source,target,relation)
	( with tbl as (
		select ef.indiv_id as source, unnest(ef.spouses) as target, 'spouseOf' as relation
		from extfamily ef order by source
	) select a.source, a.target, a.relation from tbl a, tbl b
		WHERE  (a.source, a.target) = (b.target, b.source)
		AND    a.target > a.source
	);
-- childOf [run 03May2016, +34086]
insert into test_edges(source,target,relation)
	( select ef.indiv_id as source, unnest(children) as target, 'childOf' as relation
	from extfamily ef order by source );
-- siblingOf [run 03May2016, +18685]
insert into test_edges(source,target,relation)
	( with tbl as (
		select ef.indiv_id as source, unnest(ef.siblings) as target, 'siblingOf' as relation
		from extfamily ef order by source
	) select a.source, a.target, a.relation from tbl a, tbl b
		WHERE  (a.source, a.target) = (b.target, b.source)
		AND    a.target > a.source
	);

-- some checks
select relation, count(*) from edges group by relation order by relation;
select relation, count(*) from test_edges group by relation order by relation;
select count(*) from indiv;
select source from edges where source not in (select source from test_edges);
select distinct(indiv_id) from extfamily;

-- ///////////////////////////////////////////////////////////////
-- public.similarity
-- first update similarity, then sims

delete from similarity;
-- select indiv_id from extfamily where indiv_id not in (select indiv_id from similarity); -- 1853
insert into similarity(indiv_id,byear,dyear,children,siblings)
	select e.indiv_id, coalesce(i.birthyear,i.birth_abt,i.best),coalesce(i.deathyear,i.death_abt,i.dest),
	coalesce(array_length(children,1),0), coalesce(array_length(siblings,1),0)
	from extfamily e
	join indiv i on e.indiv_id = i.indiv_id;
-- occ 11,019
with z as (
select indiv_id, to_tsvector(array_agg(occu_text)::text) as occ from indiv_occu io
	--where it.indiv_id not in (select indiv_id from similarity)
	group by indiv_id
) update similarity ts set occ = z.occ from z where ts.indiv_id = z.indiv_id;

-- event 11,930
with z as (
select i.indiv_id, to_tsvector(array_agg(e.label)::text) as event from indiv i
	join particip p on i.indiv_id = p.actor_id
	join event e on p.event_id = e.recno
	where e.type_ in ('OCCU','EDUC','EVEN','IMMI','GRAD')
	--and i.indiv_id not in (select indiv_id from similarity)
	group by i.indiv_id
) update similarity ts set event = z.event from z where ts.indiv_id = z.indiv_id;
-- loc (alternate) 21,762
with z as (
select i.indiv_id, to_tsvector(array_to_string(array_agg(coalesce(pl.admin2,'')||' '||coalesce(pl.admin1,'')||coalesce(pl.ccode,'')),' ')) as loc
	from indiv i
	join particip p on i.indiv_id = p.actor_id
	join event e on p.event_id = e.recno
	join place pl on e.place_id = pl.placeid
	--where i.indiv_id not in (select indiv_id from similarity)
	group by i.indiv_id
) update similarity ts set loc = z.loc from z where ts.indiv_id = z.indiv_id;
-- loc
-- select i.indiv_id, to_tsvector(array_agg(pl.dbname)::text) as loc from indiv i
-- 	join particip p on i.indiv_id = p.actor_id
-- 	join event e on p.event_id = e.recno
-- 	join place pl on e.place_id = pl.placeid
-- 	where i.indiv_id not in (select indiv_id from similarity)
-- 	group by i.indiv_id

-- ///////////////////////////////////////////////////////////////
-- public.sims
-- run this
select simmy();


select admin1||' '||admin2 from place
-- cleanup
update indiv set marnm = null where marnm = ''
update indiv set search_names = to_tsvector('english', coalesce(marnm,fullname))


-- select count(*) from indiv_text where professions is not null -- 11,617 people have professions
--
-- select indiv_id from indiv order by recno desc limit 100
