-- Function: p_simmy()

-- DROP FUNCTION p_simmy();

CREATE OR REPLACE FUNCTION p_simmy()
  RETURNS void AS
$BODY$
DECLARE
    _id varchar;
    _ids VARCHAR[];
BEGIN
	delete from sims;
	FOR _id IN SELECT indiv_id FROM similarity LOOP
	with w as (
	with x as(
	with y as (
	with z as (select indiv_id, ARRAY[byear,dyear,children,siblings] as vitals,
		string_to_array(replace(array_to_string(tsvector2textarray(occ),','),',unknown',''),',') as occ,
		tsvector2textarray(event) as ev, tsvector2textarray(loc) as loc from similarity
	)
	SELECT z.indiv_id,
		smlar(z.vitals, original.vitals) AS sim_vitals,
		smlar(z.occ, original.occ) AS sim_occ,
		smlar(z.ev, original.ev) AS sim_ev,
		smlar(z.loc, original.loc) AS sim_loc
		FROM z,
		(SELECT vitals, occ, ev, loc, indiv_id FROM z WHERE indiv_id = _id LIMIT 1) AS original
		WHERE z.indiv_id != original.indiv_id
		and z.occ is not null and z.vitals[1] is not null
	) select indiv_id, unnest(ARRAY[sim_vitals,sim_occ,sim_ev,sim_loc]) from y
	) select indiv_id, sum(unnest) as sim from x group by indiv_id
		order by sim desc limit 15
	) insert into sims(indiv_id, sim_id) select _id, array_agg(indiv_id) from w;

    END LOOP;

    RAISE NOTICE 'Done';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION p_simmy()
  OWNER TO cidr;
COMMENT ON FUNCTION p_simmy() IS 'computes an array of 15 most similar people using data in public.similarity and putting result in public.sims';
