-- 4) ///////////////////////////////////////////////////////////////
-- indiv_text [ ]
-- remake indiv_text (aggregates event-related verbiage)
-- ?? is occutext the only field used (earlier table has many other fields)

delete from indiv_text;
insert into indiv_text(indiv_id, occutext)
  select e.indiv_id, string_agg(e.label, '. ')
  from event e
  where e.type_ in('OCCU', 'EVEN')
  group by indiv_id;
