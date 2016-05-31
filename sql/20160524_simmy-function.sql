CREATE or replace FUNCTION simmy() RETURNS void AS $$
DECLARE
    _id varchar;
    _ids VARCHAR[];
BEGIN
	delete from test_sims;
	FOR _id IN SELECT indiv_id FROM similarity limit 10 LOOP
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
		and z.occ is not null
	-- 	ORDER BY sim_vitals DESC
	-- 	LIMIT 15;
	) select indiv_id, unnest(ARRAY[sim_vitals,sim_occ,sim_ev,sim_loc]) from y
	) select indiv_id, sum(unnest) as sim from x group by indiv_id
		order by sim desc limit 15
	) insert into test_sims(indiv_id, sim_id) select _id, array_agg(indiv_id) from w;
        --insert into test_sims(indiv_id) select id;
    END LOOP;

    RAISE NOTICE 'Done';
--     RETURN 1;
END;
$$ LANGUAGE plpgsql;

select simmy();

CREATE TABLE test_sims
(
  indiv_id character varying NOT NULL,
  sim_id character varying[],
  CONSTRAINT pkey_individ PRIMARY KEY (indiv_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE test_sims
  OWNER TO karlg;