-- 7) ///////////////////////////////////////////////////////////////
-- edges (recno,target,source,relation)
-- > depends on new extfamily
-- relation [spouseOf, childOf, siblingOf, selfLoop ]
-- [run 03May2016, before: 90270 rows, after: 97914]
drop table bak.edges;
select * into bak.edges from edges;
delete from edges;

-- selfLoop [run 03May2016, +29952; 01Jun2016]
insert into edges(source,target,relation)
  select i.indiv_id, i.indiv_id, 'selfLoop' from indiv i;
-- spouseOf [run 03May2016, +15191; 01Jun2016]
insert into edges(source,target,relation)
  ( with tbl as (
    select ef.indiv_id as source, unnest(ef.spouses) as target, 'spouseOf' as relation
    from extfamily ef order by source
  ) select a.source, a.target, a.relation from tbl a, tbl b
    WHERE  (a.source, a.target) = (b.target, b.source)
    AND    a.target > a.source
  );
-- childOf [run 03May2016, +34086; 01Jun2016]
insert into edges(source,target,relation)
  ( select ef.indiv_id as source, unnest(children) as target, 'childOf' as relation
  from extfamily ef order by source );
-- siblingOf [run 03May2016, +18685; 01Jun2016]
insert into edges(source,target,relation)
  ( with tbl as (
    select ef.indiv_id as source, unnest(ef.siblings) as target, 'siblingOf' as relation
    from extfamily ef order by source
  ) select a.source, a.target, a.relation from tbl a, tbl b
    WHERE  (a.source, a.target) = (b.target, b.source)
    AND    a.target > a.source
  );

-- some checks
-- select relation, count(*) from bak.edges group by relation order by relation
-- select relation, count(*) from edges group by relation order by relation
-- select count(*) from indiv
-- select source from bak.edges where source not in (select source from edges)
--select distinct(indiv_id) from extfamily
