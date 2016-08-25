delete from z_edges
insert into z_edges(source,target,relation)
	select right(target,-1)::int4, right(source,-1)::int4, relation from edges where relation = 'childOf' -- 34082
-- who is parentless in graph?
with z as (
select array_agg(distinct(alledges.source))::int4[] as arr from 
	(select source from z_edges union select target from z_edges ) as alledges
	where source not in (select distinct(source) from z_edges) 
) select array_length(z.arr,1) from z
-- 8396 indivs _who are in the childOf graph subset_ are not children (are parentless)

--**-- THIS WORKS! --**--
with z as (
SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
    'SELECT id::int4, source::int4 as source, target::int4 as target, 1::float8 as cost 
	FROM z_edges',
	1, (
	select array_agg(distinct(alledges.source))::int4[] as arr from 
	(select source from z_edges union select target from z_edges ) as alledges
	where source not in (select distinct(source) from z_edges) 
	)
	, true, FALSE)
) select max(cost) from z


	
-- kg family tree experiment
with z as (
SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
    'SELECT id, source::int4 as source, target::int4 as target, 1::float8 as cost 
	FROM e',
	4, array[7,8,12,17,13,15,16,18]::int4[]
	, true, FALSE)
) select max(cost) from z

-- just dijkstra
with z as (
SELECT seq, id1 AS node, id2 AS edge, cost
        FROM pgr_dijkstra(
                'SELECT id, source, target, 1::float8 as cost FROM e',
                1, 7, false, false
        )
) select sum(cost) from z;       

-- kg family tree
insert into e(source,target,rel)
	values (1,3,'childOf'),
	 (1,4,'childOf'),
	 (2,3,'childOf'),
	 (2,4,'childOf'),
	 (3,5,'childOf'),
	 (3,6,'childOf'),
	 (4,7,'childOf'),
	 (4,8,'childOf'),
	 (5,9,'childOf'),
	 (5,10,'childOf'),
	 (6,11,'childOf'),
	 (6,12,'childOf'),
	 (11,17,'childOf'),
	 (9,13,'childOf'),
	 (9,14,'childOf'),
	 (10,15,'childOf'),
	 (10,16,'childOf'),
	 (14,18,'childOf')
