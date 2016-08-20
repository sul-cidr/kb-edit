-- 3a) ///////////////////////////////////////////////////////////////
--    create indiv_dist (distance measures) records for new INDIVs
--    and begin populating

-- remove ghost indiv_dist rows (no public.indiv row)
delete from indiv_dist where indiv_id not in (select indiv_id from indiv);

-- need to add records to indiv_dist for new indiv records
insert into indiv_dist(indiv_id,odnb_id)
  select indiv_id, odnb_id from indiv i
  where i.indiv_id not in (select indiv_id from indiv_dist);

update indiv_dist set odnb = 0 where odnb_id is not null;
-- no nulls allowed, even though we're not computing these
update indiv_dist set centrality = 0 where centrality is null;
update indiv_dist set inbred = 0 where inbred is null;

-- 3b requires extfamily, moved to #6

-- 3c) ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
-- create indiv_dist.odnb_id value for new indivs with odnb_id !!!
update indiv_dist id set odnb_id = i.odnb_id from indiv i
  where i.indiv_id = id.indiv_id and i.odnb_id is not null;
-- get word count for all odnbers
update indiv_dist id set
  odnb_wordcount = o.words
  from odnbers o
  where id.odnb_id is not null
  and o.odnb_id = id.odnb_id;
