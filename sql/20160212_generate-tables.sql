-- sql to generate kb1 tables
-- indiv_text, indiv_events, extfamily, edges, 
-- ///////////////////////////////////////////////////////////////
-- indiv_text
select from indiv_text -- 11,617 not everyone is in here "everyone for whom there is OCCU, EVEN or RESI text"
select count(*) from indiv_dist where odnb = 0 -- 4432
select distinct on(indiv_id) p.* from particip p join event e on p.event_id = e.recno
	where e.type in('OCCU','EVEN') -- 11,550 of 29938 in indiv
-- so indiv_occu records should be created directly as part of indiv record
with z as (select char_length(occutext) as len from indiv_text 
) select max(len) from z -- 5643
select indiv_id from indiv_text where char_length(occutext) > 3000

-- use this for indiv_text ------------------------------------------
select e.indiv_id, string_agg(e.label, '. ') AS occutext 
	into test_indivtext
	from event e
	where e.type in('OCCU', 'EVEN')
	group by indiv_id
--------------------------------------------------------------------

-- ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id

delete from test_indiv_events;
insert into test_indiv_events(indiv_id, particip_array)
	with y as (
		with z as ( select e.recno AS event_id,
			array_accum(p.actor_id) as particip_array
			from event e, particip p 
			where e.recno = p.event_id 
			-- filter those with unknown year
 			and coalesce(year,year_abt,year_est) is not null
			group by e.recno
			order by event_id ) -- z
				select  e.type as eventtype, e.label as eventlabel, e.place as eventplace, 
				period_text as eventdate, e.place_id AS place,
				coalesce(year,year_abt,year_est,-1) as Year,
				case when(year_abt is not null OR year_est is not null) then 'roughly' 
				     when year > 0 then 'known'
				     else ''
				end as accuracy,
				z.particip_array as actor
				from z join event e on z.event_id = e.recno
	) -- y
	select i.indiv_id, 
	'['||
	array_to_string(
	array_agg('{"eventtype":"'||y.eventtype||'","eventlabel":"'||y.eventlabel||
		'","eventplace":"'||coalesce(y.eventplace,'')||'","eventdate":"'||
		coalesce(y.eventdate,'foo')||'"'||
		case when y.place IS null then ''
		     ELSE ',"place":'||coalesce(y.place::text,'""')
		     end ||
		     ',"year":'||(y.year-coalesce(e.year,e.year_abt,e.year_est,-1)) || -- age at event if birth known
-- 		case when i.birthyear IS null then ''
-- 		     ELSE ',"year":'||(y.year-i.birthyear) -- age at event if birth known
--		     end ||
		',"accuracy":"'||coalesce(y.accuracy,'')||
		'","actor":'||'["'||array_to_string(y.actor,'","')||'"]}'),',')||
	']' 
	from indiv i 
	join y on i.indiv_id = any(y.actor)
	join particip p on i.indiv_id=p.actor_id
	join event e on p.event_id = e.recno
	where p.role = 'child' 
	-- and i.indiv_id = 'I274' 
	group by i.indiv_id order by indiv_id -- limit 3


-- ///////////////////////////////////////////////////////////////
-- create extfamily
-- given current 'indiv', 'event', and 'particip' tables
-- ///////////////////////////////////////////////////////////////
-- uses helpers:
	-- p_parent(indiv_id,['mother' | 'father'])
	-- p_spouses(indiv_id)
	-- p_children(indiv_id)
	-- p_siblings()
	
-- takes 45+ minutes in pgadmin
delete from test_extfamily;
insert into test_extfamily(indiv_id,sex,mother,father,spouses,children,siblings,
		birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
	select i.indiv_id, i.sex, 
	p_parent(i.indiv_id,'mother'), 
	p_parent(i.indiv_id,'father'),
	p_spouses(indiv_id),
	p_children(indiv_id),
	p_siblings(indiv_id),
	i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
	from indiv i order by indiv_id; -- limit 120;

-- ///////// these 3 collapsed into helper functions ////////////////////////
-- spouses
--update test_extfamily set spouses =
	with z as ( select unnest(array_accum(actor_id)) as betrothed from particip 
		where event_id = ANY(select event_id from particip where 
		actor_id = 'I10089' and (role = 'wife' or role = 'husband')) ) 
	select array_accum(betrothed) from z where betrothed != 'I10089'
	--where indiv_id = 'I10089';
-- ///////////////////////////////////////////////////////////////
-- children
--update test_extfamily set children = 
	(select array_accum(actor_id) from particip where event_id in 
	 (select event_id from particip where actor_id = 'I10032' and (role = 'mother' or role = 'father'))
	 and role = 'child')
	 --where indiv_id = 'I10032';
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children (all rows)
--update test_extfamily set siblings =  (
	with z as (
	select unnest(children) 
		from test_extfamily where 'I1' = any(children)
	) select array_accum(distinct(unnest)) from z where unnest != 'I1'
 

-- ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [spouseOf, childOf, siblingOf, selfLoop ]
delete from test_edges;
-- selfLoop
insert into test_edges(source,target,relation)
	select i.indiv_id, i.indiv_id, 'selfLoop' from indiv i;

-- spouseOf
insert into test_edges(source,target,relation)
	( with tbl as (
		select ef.indiv_id as source, unnest(ef.spouses) as target, 'spouseOf' as relation 
		from test_extfamily ef order by source
	) select a.source, a.target, a.relation from tbl a, tbl b 
		WHERE  (a.source, a.target) = (b.target, b.source)
		AND    a.target > a.source  
	);
-- childOf
insert into test_edges(source,target,relation)
	( select ef.indiv_id as source, unnest(children) as target, 'childOf' as relation 
	from test_extfamily ef order by source );
-- siblingOf
insert into test_edges(source,target,relation)
	( with tbl as (
		select ef.indiv_id as source, unnest(ef.siblings) as target, 'siblingOf' as relation 
		from test_extfamily ef order by source
	) select a.source, a.target, a.relation from tbl a, tbl b 
		WHERE  (a.source, a.target) = (b.target, b.source)
		AND    a.target > a.source  
	);
-- checks
select relation, count(*) from edges group by relation order by relation
select relation, count(*) from test_edges group by relation order by relation
select count(*) from indiv
select source from edges where source not in (select source from test_edges)
select distinct(indiv_id) from test_extfamily



-- ///////////////////////////////////////////////////////////////
-- indiv_occu
-- don't generate this - populate from form for indiv

select count(*) from indiv_text where professions is not null -- 11,617 people have professions

select indiv_id from indiv order by recno desc limit 100
