-- HELPER FUNCTIONS
-- array_accum(anyelement)
-- p_parent('I10090','mother')
-- p_spouses('I10014')

-- select p_parent('I10090','mother')
-- drop FUNCTION p_parent(text, text)
CREATE OR REPLACE FUNCTION p_parent(individ text, which TEXT)
  RETURNS varchar as 
$$ 
with z as ( select p.event_id,p.actor_id,p.role
	from particip p join event e on p.event_id=e.recno
	where p.role = 'child' and p.actor_id = $1 )
	select 
	p1.actor_id from particip p1, z where p1.event_id = z.event_id
	and p1.role = $2;
$$ 
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION p_parent(text,TEXT)
  OWNER TO power;
GRANT EXECUTE ON FUNCTION p_parent(text,text) TO public;
GRANT EXECUTE ON FUNCTION p_parent(text,text) TO webapp;

-- select p_spouses('I10014')
-- drop FUNCTION p_spouses(text, text)
CREATE OR REPLACE FUNCTION p_spouses(individ text)
  RETURNS varchar[] as 
$$ 
	(with z as ( select unnest(array_accum(actor_id)) as betrothed from particip 
		where event_id = ANY(select event_id from particip where 
		actor_id = $1 and (role = 'wife' or role = 'husband')) ) 
	select array_accum(distinct(betrothed)) from z where betrothed != $1)
$$ 
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION p_spouses(text)
  OWNER TO power;
GRANT EXECUTE ON FUNCTION p_spouses(text) TO public;
GRANT EXECUTE ON FUNCTION p_spouses(text) TO webapp;

-- select p_children('I1')
-- drop FUNCTION p_children(text, text)
CREATE OR REPLACE FUNCTION p_children(individ text)
  RETURNS varchar[] as 
$$ 
	(select array_accum(actor_id) from particip where event_id in 
	 (select event_id from particip where actor_id = $1 and (role = 'mother' or role = 'father'))
	 and role = 'child')
$$ 
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION p_children(text)
  OWNER TO power;
GRANT EXECUTE ON FUNCTION p_children(text) TO public;
GRANT EXECUTE ON FUNCTION p_children(text) TO webapp;


-- select p_siblings('I1')
-- drop FUNCTION p_siblings(text, text)
CREATE OR REPLACE FUNCTION p_siblings(individ text)
  RETURNS varchar[] as 
$$ 
	with z as (
	select unnest(children) 
		from test_extfamily where $1 = any(children)
	) select array_accum(distinct(unnest)) from z where unnest != $1
	
$$ 
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION p_siblings(text)
  OWNER TO power;
GRANT EXECUTE ON FUNCTION p_siblings(text) TO public;
GRANT EXECUTE ON FUNCTION p_siblings(text) TO webapp;


-- aggregates any element
CREATE AGGREGATE array_accum (anyelement)
(
    sfunc = array_append,
    stype = anyarray,
    initcond = '{}'
);
-- // 