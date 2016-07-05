-- 6) ///////////////////////////////////////////////////////////////
-- create extfamily
-- given current 'indiv', 'event', and 'particip' tables
-- ///////////////////////////////////////////////////////////////
-- uses helpers:
  -- p_parent(indiv_id,['mother' | 'father'])
  -- p_spouses(indiv_id)
  -- p_children(indiv_id)
  -- p_siblings()
drop table bak.extfamily;
select * into bak.extfamily from extfamily;
delete from extfamily;
-- [run 03May2016, 29952 rows 14+ min.; 01Jun2016 wo/spouse,children, ~14 min]
-- ERROR: null value in column "recno" violates not-null constraint
-- cause: moving/copying table between schemas changed serial sequence to plain integer
select * from event where recno is null
insert into extfamily(indiv_id,sex,mother,father,-- spouses,children, -- siblings,
    birthyear,birth_abt,birth_est,deathyear,death_abt,death_est)
  select i.indiv_id, i.sex,
  p_parent(i.indiv_id,'mother'),
  p_parent(i.indiv_id,'father'),
--  p_spouses(indiv_id),
-- p_children(indiv_id),
-- p_siblings(indiv_id), -- depends on children
  i.birthyear,i.birth_abt,i.best,i.deathyear,i.death_abt,i.dest
  from indiv i order by indiv_id; -- limit 120;

-- ///////// run helper functions all run 01Jun2016 ////////////////////////
-- spouses
update extfamily set spouses = p_spouses(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- children
update extfamily set children = p_children(indiv_id); -- 10 min.
-- ///////////////////////////////////////////////////////////////
-- siblings; depends on children (all rows)
update extfamily set siblings = p_siblings(indiv_id); -- 3.6 min.
-- test: seems ok
-- select * from extfamily where indiv_id = 'I30349' -- Turing; ok
-- select * from extfamily where indiv_id = 'I30347' -- Turing's father; ok
