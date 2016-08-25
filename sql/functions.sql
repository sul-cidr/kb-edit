-- Function: p_simmy()

-- p_odnb()
DECLARE _id varchar;                                                                                                               +
 begin                                                                                                                              +
 FOR _id IN SELECT indiv_id FROM indiv_dist LOOP                                                                                    +
    begin                                                                                                                           +
          with y as (                                                                                                               +
          with z as (                                                                                                               +
          SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(                                                    +
              'SELECT recno::int4 as id, right(source,-1)::int4 as source,                                                          +
             right(target,-1)::int4 as target, 1::float8 as cost FROM edges where relation != ''selfLoop''',                        +
              right(_id,-1)::int4, (select array_agg(right(indiv_id,-1)::int) AS arr from indiv_dist where odnb = 0) , false, false)+
          ) select _id as indiv_id, min(cost) as foo from z                                                                         +
          ) update indiv_dist id set odnb = y.foo from y where y.indiv_id = id.indiv_id;                                            +
          exception when others then                                                                                                +
             -- no problem, these people are not in public.indiv                                                                    +
             RAISE NOTICE 'error on (%)', _id;                                                                                      +
             update indiv_dist id set odnb = -1 where _id = id.indiv_id;                                                            +
    END;                                                                                                                            +
 END LOOP;                                                                                                                          +
                                                                                                                                    +
 RAISE NOTICE 'Done';                                                                                                               +
 END;

-- p_parentless()
DECLARE _id varchar;                                                                                         +
 begin                                                                                                        +
   -- update z_edges for this calculation                                                                     +
   delete from z_edges;                                                                                       +
   insert into z_edges(source,target,relation)                                                                +
     select right(target,-1)::int4, right(source,-1)::int4, relation from edges where relation in ('childOf');+
   FOR _id IN SELECT indiv_id FROM indiv_dist LOOP                                                            +
       begin                                                                                                  +
          with y as (                                                                                         +
          with z as (                                                                                         +
          SELECT seq, id1 AS source, id2 AS target, cost FROM pgr_kdijkstraCost(                              +
              'SELECT id::int4, source::int4 as source, target::int4 as target, 1::float8 as cost             +
             FROM z_edges',                                                                                   +
             right(_id,-1)::int4, (                                                                           +
             select array_agg(distinct(alledges.source))::int4[] as arr from                                  +
             (select source from z_edges union select target from z_edges ) as alledges                       +
             where source not in (select distinct(source) from z_edges)                                       +
             )                                                                                                +
             , true, FALSE)                                                                                   +
          ) select max(cost) as foo from z                                                                    +
          ) update indiv_dist id set parentless = y.foo from y where _id = id.indiv_id;                       +
           exception when others then                                                                         +
             RAISE NOTICE 'error on (%)', _id;                                                                +
             -- these are people with no parents or children & get a 0                                        +
             update indiv_dist id set parentless = 0 where _id = id.indiv_id;                                 +
       END;                                                                                                   +
   END LOOP;                                                                                                  +
                                                                                                              +
 RAISE NOTICE 'Done';                                                                                         +
 END;

-- p_simmy()
DECLARE                                                                                                          +
    _id varchar;                                                                                                 +
    _ids VARCHAR[];                                                                                              +
BEGIN                                                                                                            +
        delete from sims;                                                                                        +
        FOR _id IN SELECT indiv_id FROM similarity LOOP                                                          +
        with w as (                                                                                              +
        with x as(                                                                                               +
        with y as (                                                                                              +
        with z as (select indiv_id, ARRAY[byear,dyear,children,siblings] as vitals,                              +
                string_to_array(replace(array_to_string(tsvector2textarray(occ),','),',unknown',''),',') as occ, +
                tsvector2textarray(event) as ev, tsvector2textarray(loc) as loc from similarity                  +
        )                                                                                                        +
        SELECT z.indiv_id,                                                                                       +
                smlar(z.vitals, original.vitals) AS sim_vitals,                                                  +
                smlar(z.occ, original.occ) AS sim_occ,                                                           +
                smlar(z.ev, original.ev) AS sim_ev,                                                              +
                smlar(z.loc, original.loc) AS sim_loc                                                            +
                FROM z,                                                                                          +
                (SELECT vitals, occ, ev, loc, indiv_id FROM z WHERE indiv_id = _id LIMIT 1) AS original          +
                WHERE z.indiv_id != original.indiv_id                                                            +
                and z.occ is not null and z.vitals[1] is not null                                                +
        ) select indiv_id, unnest(ARRAY[sim_vitals,sim_occ,sim_ev,sim_loc]) from y                               +
        ) select indiv_id, sum(unnest) as sim from x group by indiv_id                                           +
                order by sim desc limit 15                                                                       +
        ) insert into sims(indiv_id, sim_id) select _id, array_agg(indiv_id) from w;                             +
                                                                                                                 +
    END LOOP;                                                                                                    +
                                                                                                                 +
    RAISE NOTICE 'Done';                                                                                         +
                                                                                                                 +
END;
