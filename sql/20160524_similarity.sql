-- top summed similarity values from similarity table int sims table
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
	(SELECT vitals, occ, ev, loc, indiv_id FROM z WHERE indiv_id = 'I1000' LIMIT 1) AS original
	WHERE z.indiv_id != original.indiv_id
	and z.occ is not null
) select indiv_id, unnest(ARRAY[sim_vitals,sim_occ,sim_ev,sim_loc]) from y
) select indiv_id, sum(unnest) as sim from x group by indiv_id
	order by sim desc limit 15
) select array_agg(indiv_id) from w
-- 	update test_sims set sim_id = array_agg(id) from w where test_sims.indiv_id = 'I1'

