-- 4) ///////////////////////////////////////////////////////////////
-- indiv_text [run 03May2016, 11555 rows; 31May2016, 11555 rows]
-- ?? is occutext the only field used (earlier table has many other fields)

delete from indiv_text;
insert into indiv_text(indiv_id, occutext)
  select e.indiv_id, string_agg(e.label, '. ')
  from event e
  where e.type_ in('OCCU', 'EVEN')
  group by indiv_id;