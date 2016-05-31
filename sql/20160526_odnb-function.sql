-- select p_odnb(); 170 min!!!! (3/sec)
-- select * from edges where relation != 'selfLoop' and source = 'I11411'
-- where recno > 1300 and recno < 1500
-- DROP FUNCTION p_odnb();

CREATE OR REPLACE FUNCTION p_odnb()
  RETURNS void AS
$BODY$
DECLARE _id varchar;
begin
	FOR _id IN SELECT indiv_id FROM indiv_dist LOOP
	   begin
         with y as (
         with z as (
         SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
             'SELECT recno::int4 as id, right(source,-1)::int4 as source, 
            right(target,-1)::int4 as target, 1::float8 as cost FROM edges where relation != ''selfLoop''',
             right(_id,-1)::int4, (select array_agg(right(indiv_id,-1)::int) AS arr from indiv where odnb_id is not null) , false, false)
         ) select _id as indiv_id, min(cost) as foo from z
         ) update indiv_dist id set odnb = y.foo from y where y.indiv_id = id.indiv_id;
         exception when others then
            -- no problem, these people are not in public.indiv
            RAISE NOTICE 'error on (%)', _id;
            update indiv_dist id set odnb = -1 where _id = id.indiv_id;
	   END;
	END LOOP;

RAISE NOTICE 'Done';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION p_odnb()
  OWNER TO karlg;
COMMENT ON FUNCTION p_odnb() IS 'computes number of hops to closest ODNBer';

