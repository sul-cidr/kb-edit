-- parentless function
-- select p_parentless(); ~ 5.3 min per 1000
CREATE OR REPLACE FUNCTION p_parentless()
  RETURNS void AS
$BODY$
DECLARE _id varchar;
begin
	-- use filtered z_edges for this calculation
	delete from z_edges;
	insert into z_edges(source,target,relation)
		select right(target,-1)::int4, right(source,-1)::int4, relation from edges where relation in ('childOf');
	FOR _id IN SELECT indiv_id FROM indiv_dist LOOP
      begin
         with y as (
         with z as (
         SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
             'SELECT id::int4, source::int4 as source, target::int4 as target, 1::float8 as cost 
            FROM z_edges',
            right(_id,-1)::int4, (
            select array_agg(distinct(alledges.source))::int4[] as arr from 
            (select source from z_edges union select target from z_edges ) as alledges
            where source not in (select distinct(source) from z_edges) 
            )
            , true, FALSE)
         ) select max(cost) as foo from z
         ) update indiv_dist id set parentless = y.foo from y where _id = id.indiv_id;
          exception when others then
            RAISE NOTICE 'error on (%)', _id;
            -- these are people with no parents or children & get a 0
            update indiv_dist id set parentless = 0 where _id = id.indiv_id;
      END;
	END LOOP;

RAISE NOTICE 'Done';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION p_parentless()
  OWNER TO karlg;
COMMENT ON FUNCTION p_parentless() IS 'computes # generations (hops to closest parentless indiv)';