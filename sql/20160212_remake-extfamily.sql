-- select p_remake_extfamily()
-- Function: p_remake_extfamily(text)
-- DROP FUNCTION p_remake_extfamily(text)

CREATE OR REPLACE FUNCTION p_remake_extfamily()
  RETURNS void AS
$BODY$
DECLARE
    r record;
    indivId varchar;
BEGIN
    EXECUTE 'DELETE FROM test_extfamily';
    FOR indivId IN SELECT indiv_id FROM indiv order by indiv_id limit 10
    LOOP
	with z as ( select p.event_id,p.actor_id,p.role
		from particip p join event e on p.event_id=e.recno
		where p.role = 'child' and p.actor_id = indivId ) 
	insert into test_extfamily(indiv_id,sex,mother,father,birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
		select z.actor_id as indiv_id,i.sex,
		-- p1.actor_id as mother, p2.actor_id as father,
		case when p1.actor_id = z.actor_id THEN null else p1.actor_id end as mother,
		case when p2.actor_id = z.actor_id THEN null else p2.actor_id end as father,
		i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
		from z
		join particip p1 on z.event_id = p1.event_id
		join particip p2 on z.event_id = p2.event_id
		join indiv i on z.actor_id = i.indiv_id
		where p1.event_id=z.event_id and p2.event_id=z.event_id;
    END LOOP;
    RETURN;
END


$BODY$
  LANGUAGE plpgsql VOLATILE STRICT
  COST 100;
ALTER FUNCTION p_remake_extfamily()
  OWNER TO power;
GRANT EXECUTE ON FUNCTION p_remake_extfamily() TO public;
GRANT EXECUTE ON FUNCTION p_remake_extfamily() TO webapp;

