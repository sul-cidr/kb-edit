-- Function: p_indivoccu(text)

-- DROP FUNCTION p_indivoccu(text);

CREATE OR REPLACE FUNCTION p_indivoccu(individ text)
  RETURNS SETOF character varying AS
$BODY$
with 
s as ( with 
r as (
select i.indiv_id, i.fullname, io.occu, o.parent_class
	from indiv i
	join indiv_occu io on i.indiv_id=io.indiv_id
	join occu o on io.occu=o.class
	where i.indiv_id = $1
)
select r.indiv_id, r.parent_class, o2.parent_class AS grandparent from r
	join occu o2 on r.parent_class=o2.class
)
select coalesce(grandparent, parent_class) AS uber
	from s group by uber

$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION p_indivoccu(text)
  OWNER TO karlg;
