select * from edges limit 100
-- tests
drop table z_edges
select * into z_edges from edges where relation != 'selfLoop' limit 1000

WITH RECURSIVE search_graph(source, target, depth) AS (
        SELECT g.source, g.target, 1
        FROM edges g 
      UNION ALL
        SELECT g.source, g.target, sg.depth + 1
        FROM edges g, search_graph sg
        WHERE g.source = sg.target
        and sg.target in (select indiv_id from indiv_dist where odnb_id is not null)
)
SELECT * into z_edgelengths FROM search_graph;

select distinct(odnb) from indiv

