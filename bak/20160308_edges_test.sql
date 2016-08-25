-- drop table edges_test
CREATE TABLE edges_test
(
  recnum serial,
  source integer,
  target integer,
  relation character varying(16),
  CONSTRAINT pk_edgestest PRIMARY KEY (recnum)
)
WITH (
  OIDS=FALSE
);
-- ALTER TABLE edges_test
--   OWNER TO power;
-- GRANT ALL ON TABLE edges_test TO power;
-- GRANT SELECT ON TABLE edges_test TO public;

-- drop table indiv_test
CREATE TABLE indiv_test
(
  recnum serial,
  indiv_id integer,
  iname character varying(16),
  CONSTRAINT pk_indiv_test PRIMARY KEY (recnum)
)
WITH (
  OIDS=FALSE
);


insert into edges_test(source,target,relation)  values 
  (1,2,'childOf'),
  (2,3,'childOf'),
  (5,4,'childOf'), 
  (4,6,'childOf'),
  (4,7,'childOf'),
  (6,8,'childOf'),
  (1,1,'selfLoop'),
  (2,2,'selfLoop'),
  (3,3,'selfLoop'),
  (4,4,'selfLoop'),
  (5,5,'selfLoop'),
  (6,6,'selfLoop'),
  (7,7,'selfLoop'),
  (8,8,'selfLoop'),
  (9,9,'selfLoop');

insert into indiv_test(indiv_id,iname) values
  (1,'indiv1'),
  (2,'indiv2'),
  (3,'indiv3'),
  (4,'indiv4'),
  (5,'indiv5'),
  (6,'indiv6'),
  (7,'indiv7'),
  (8,'indiv8'),
  (9,'indiv9');
	
-- with z as (

SELECT seq, id1 AS source, id2 AS target, cost
	FROM pgr_kdijkstraCost('
		SELECT
		recnum as id,
		source, target, 1::double precision as cost FROM edges_test',
		7,
		(select ARRAY[1,5,9]),
		false,
		false
	)
	
	--LEFT JOIN indiv_test it ON it.indiv_id = vertex_id_target
-- ) select -- max(cost) from z
-- indiv_id, cost from z where cost >= 0 order by cost --desc

SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(
’SELECT id, source, target, cost FROM edge_table’,
10, array[4,12], false, false
);


