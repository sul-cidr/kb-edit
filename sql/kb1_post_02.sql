-- 2) ///////////////////////////////////////////////////////////////
-- tragic (run time ~14 min) [run 02May2016, 29952 rows; 31May2016, ]
-- "Make sure to set dest = 2013 to dest = 2099 before running this"
-- Array is diedyoung,earlyspouse,earlysibling,earlychild,earlyparent

UPDATE indiv SET dest = 2099 WHERE dest = 2013;

DROP TABLE tragic;

CREATE TABLE tragic AS
  SELECT indiv.indiv_id,
  SUM(
  CASE
  when target.indiv_id IS NULL AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 45  then 1
  else 0
  END
  ) as diedyoung,

  SUM(
  (
  CASE
  when edges.relation = 'spouseOf' AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(target.deathyear,target.death_abt,target.dest) >= 20 then 1
  when edges.relation = 'siblingOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) < COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 12 then 1
  else 0
  END
  )
  ) as total,
  ''||

  SUM(
  (
  CASE
  when edges.relation = 'spouseOf' AND COALESCE(indiv.deathyear,indiv.death_abt,indiv.dest) - COALESCE(target.deathyear,target.death_abt,target.dest) >= 20 then 1
  else 0
  END
  )
  )||','||

  SUM(
  (
  CASE
  when edges.relation = 'siblingOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  else 0
  END
  )
  )||','||
  SUM(
  (
  CASE
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) > COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(target.birthyear,target.birth_abt,target.best) <= 12 then 1
  else 0
  END
  )
  )||','||
  SUM(
  (
  CASE
  when edges.relation = 'childOf' AND COALESCE(target.birthyear,target.birth_abt,target.best) < COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) AND COALESCE(target.deathyear,target.death_abt,target.dest) - COALESCE(indiv.birthyear,indiv.birth_abt,indiv.best) <= 12 then 1
  else 0
  END
  )
  ) as trarray
  FROM indiv
  LEFT JOIN edges ON indiv.indiv_id IN (edges.source, edges.target)
  LEFT JOIN indiv as target ON target.indiv_id IN (edges.source, edges.target) AND target.indiv_ID <> indiv.indiv_id
  GROUP BY indiv.indiv_id;

UPDATE indiv SET dest = 2013 WHERE dest = 2099;
-- new people for whom we have no death year
update indiv set dest = 2013 where deathyear is null and death_abt is null and dest is null;
