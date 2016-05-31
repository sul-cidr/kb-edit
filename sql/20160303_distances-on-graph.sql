-- distances to odnber, parentless
-- ODNB
-- put this on a function
with z as (
SELECT indiv_id, cost
	FROM KDijkstra_dist_sp('
		SELECT
		recno as id,
		(substr(source, 2, length(source) - 1))::integer as source,
		(substr(target, 2, length(target) - 1))::integer as target,
		1::double precision as cost FROM edges',
		5906,
		(select array_agg(trim(leading 'I' from indiv_id)::integer) as odnbers from indiv where odnb_id is not null),
		false,
		false
	)
	LEFT JOIN indiv ON indiv.indiv_id = 'I'||vertex_id_target
) select min(cost) from z

-- PARENTLESS
-- make array of parentless
-- 12691 indivs who aren't a target in edges relation = 'childOf' records
select array_agg(trim(leading 'I' from indiv_id)::integer)  from indiv where indiv_id not in 
	(select distinct(target) from edges where relation = 'childOf')
-- put this on a function
with z as (
SELECT indiv_id, cost
	FROM KDijkstra_dist_sp('
		SELECT
		recno as id,
		(substr(source, 2, length(source) - 1))::integer as source,
		(substr(target, 2, length(target) - 1))::integer as target,
		1::double precision as cost FROM edges 
		where relation in (''childOf'',''selfLoop'')',
		7654, -- Amy Ruck known parentless;
		-- 1, --
		(select array_agg(trim(leading 'I' from indiv_id)::integer) from indiv where indiv_id not in 
			(select distinct(target) from edges where relation = 'childOf')),
		false,
		false
	)
	LEFT JOIN indiv ON indiv.indiv_id = 'I'||vertex_id_target
) select -- max(cost) from z
indiv_id, cost from z where cost >= 0 order by cost --desc

select * from edges where source = 'I7648'
union
select * from edges where source = 'I7655'

-- (substr(source, 2, length(source) - 1))::integer
--  where relation not in (''spouseOf'',''siblingOf'')
--  where relation in (''childOf'',''selfLoop'')'

select fullname from indiv where indiv_id = 'I21576' -- [Mary] Louisa Bernier
select * from indiv where indiv_id = 'I21577'


delete from z_bloodedges where 
	source in (select indiv_id from indiv where indiv_id not in 
	(select distinct(target) from edges where relation = 'childOf'))
delete from z_bloodedges where 
	target in (select indiv_id from indiv where indiv_id not in 
	(select distinct(target) from edges where relation = 'childOf'))

drop table z_bloodedges
select * into z_bloodedges from edges

select distinct(relation) from edges
