-- sql to generate kb1 tables

-- ///////////////////////////////////////////////////////////////
-- indiv_text
select from indiv_text -- 11,617 not everyone is in here "everyone for whome there is OCCU, EVEN or RESI text"
select count(*) from indiv_dist where odnb = 0 -- 4432
select distinct on(indiv_id) p.* from particip p join event e on p.event_id = e.recno
	where e.type = 'OCCU' -- 11,197
-- so indiv_occu records should be created directly as part of indiv record
with z as (select char_length(occutext) as len from indiv_text 
) select max(len) from z -- 5643
select indiv_id from indiv_text where char_length(occutext) > 3000

-- use this for indiv_text ------------------------------------------
select e.indiv_id, string_agg(e.label, '. ') AS occutext from event e
	where e.type in('OCCU', 'EVEN')
	group by indiv_id
--------------------------------------------------------------------

-- ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id

-- // helper
CREATE AGGREGATE array_accum (anyelement)
(
    sfunc = array_append,
    stype = anyarray,
    initcond = '{}'
);
-- // 

drop table z_indivevents;

with y as (
with z as (
	select e.recno AS event_id,
		array_accum(p.actor_id) as particip_array
		from event e, particip p where e.recno = p.event_id group by e.recno
		order by event_id
	)
select  e.type as eventtype, e.label as eventlabel, e.place as eventplace, 
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
		'","eventplace":"'||coalesce(y.eventplace,'')||
		'","eventdate":"'||coalesce(y.eventdate,'')||
		case when y.place IS null then '"'
		     ELSE '","place":'||coalesce(y.place::text,'""')
 		     end ||
		case when i.birthyear IS null then '"'
		     ELSE ',"year":'||(y.year-i.birthyear) -- age at event if birth known
 		     end ||
		',"accuracy":"'||coalesce(y.accuracy,'')||
		'","actor":'||'["'||array_to_string(y.actor,'","')||'"]}'),',')||
	']' as particip_array
	-- into test_indivevents
	from indiv i join y on i.indiv_id = any(y.actor)
	group by i.indiv_id order by indiv_id


-- compare with existing 
-- select * from indiv_events order by indiv_id limit 100
-- select * from z_indivevents order by indiv_id

-- ///////////////////////////////////////////////////////////////
-- create extfamily(indiv_id)
-- TODO: wrap in a function
-- given current 'indiv', 'event', and 'particip' -->
-- ///////////////////////////////////////////////////////////////
-- indiv, mother and father ; test with I10032
-- delete from test_extfamily;
-- this gets only those with mother and father
delete from test_extfamily;
insert into test_extfamily(indiv_id,sex,mother,father,birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
	select i.indiv_id, i.sex, p_parent(i.indiv_id,'mother'), p_parent(i.indiv_id,'father'),
	i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
	from indiv i order by indiv_id limit 120
	
with z as ( select p.event_id,p.actor_id,p.role
	from particip p join event e on p.event_id=e.recno
	where p.role = 'child' and p.actor_id = 'I10090' ) --I10090 1 parent
insert into test_extfamily(indiv_id,sex,mother,father,birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
	select z.actor_id as indiv_id,i.sex,
	p_parent('I10090','mother') as mother,
	p_parent('I10090','father') as father,
	i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
	from z
	join indiv i on z.actor_id = i.indiv_id
	
-- ///////////////////////////////////////////////////////////////
-- troubleshooting

	-- where indiv_id = 'I10090'

with z as ( select p.event_id,p.actor_id,p.role
	from particip p join event e on p.event_id=e.recno
	where p.role = 'child' and p.actor_id = 'I10001' )
	select 
	p1.actor_id from particip p1, z where p1.event_id = z.event_id
	and p1.role = 'father'


select p.* from particip p join event e on p.event_id = e.recno 
	where e.type = 'BIRT' and p.actor_id = 'I10090'

-- spouses
update test_extfamily set spouses =
	(with z as ( select unnest(array_accum(actor_id)) as betrothed from particip 
		where event_id = ANY(select event_id from particip where 
		actor_id = 'I10032' and (role = 'wife' or role = 'husband')) ) 
	select array_accum(betrothed) from z where betrothed != 'I10032')
	where indiv_id = 'I10032';
-- ///////////////////////////////////////////////////////////////
-- children
update test_extfamily set children = 
	(select array_accum(actor_id) from particip where event_id in 
	 (select event_id from particip where actor_id = 'I10032' and (role = 'mother' or role = 'father'))
	 and role = 'child')
	 where indiv_id = 'I10032';
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children
update test_extfamily set siblings =  (
	with z as (
	select unnest(children) 
		from test_extfamily where 'I10032' = any(children)
	) select array_accum(unnest) from z where unnest != 'I10032'
	) where test_extfamily.indiv_id = 'I10032';
-- ///////////////////////////////////////////////////////////////



-- ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [siblingOf, selfLoop, childOf, spouseOf]

select distinct(target) from edges-- where source = 'I2135'

select i.indiv_id as source, i.indiv_id as target, 'selfLoop' as relation
	from indiv i
union
select 

	
-- ///////////////////////////////////////////////////////////////
-- indiv_occu
-- don't generate this - populate from form for indiv

select count(*) from indiv_text where professions is not null -- 11,617 people have professions

select indiv_id from indiv order by recno desc limit 100
