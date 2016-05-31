select * from edges limit 100
-- tests
drop table z_edges
drop table z_edgelengths

--// ODNB DISTANCE
-- array of odnbers
select array_agg(right(indiv_id,-1)::int) AS arr from indiv where odnb_id is not null

with y as (
with z as (
SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
    'SELECT recno as id, right(source,-1)::int4 as source, 
	right(target,-1)::int4 as target, 1::float8 as cost FROM edges where relation != ''selfLoop''',
    30346, (select array_agg(right(indiv_id,-1)::int) AS arr from indiv where odnb_id is not null) , false, false)
) select 'I'||30346 as indiv_id, min(cost) as foo from z
-- ) select foo from y
) update indiv_dist id set odnb = y.foo from y where y.indiv_id = id.indiv_id
-- test insert
    
select odnb from indiv_dist where indiv_id = 'I30349'


--// PARENTLESS DISTANCE
-- update z_edges for this calculation
delete from z_edges;
-- reverse source, target
insert into z_edges(source,target,relation)
	select right(target,-1)::int4, right(source,-1)::int4, relation from edges where relation = 'childOf'; -- 34082
select * from z_edges limit 100;
-- array of 8396 parentless within z_edges (not in childOf relation)
with z as (
select array_agg(distinct(alledges.source))::int4[] as arr from 
	(select source from z_edges union select target from z_edges ) as alledges
	where source not in (select distinct(source) from z_edges)
) select array_length(z.arr,1) from z

-- directed shortest path sum(cost) to a parentless person
-- put this in a function to fill indiv_dist.parentless field
with y as (
with z as (
SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
    'SELECT id::int4, source::int4 as source, target::int4 as target, 1::float8 as cost 
	FROM z_edges',
	30349, (
	select array_agg(distinct(alledges.source))::int4[] as arr from 
	(select source from z_edges union select target from z_edges ) as alledges
	where source not in (select distinct(source) from z_edges) 
	)
	, true, FALSE)
) select max(cost)::int4 as foo from z
) select y.foo from y

select * from indiv_dist where odnb is null
