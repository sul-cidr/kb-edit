-- generating indiv_dist and related (tragedy index)

-- ///////////////////////////////////////////////////////////////
-- trag_text [run 02May2016, 29952 records]
delete from trag_text;
insert into trag_text(indiv_id,deathtext,eventext)
	SELECT indiv.indiv_id,
	string_agg(DISTINCT COALESCE(event.place_text,' ')||COALESCE(event.notes,' ')||COALESCE(event.cause,' ')||
		COALESCE(event.label,' '),' '), -- as deathtext,
	replace(string_agg(DISTINCT COALESCE(event2.place_text,' ')||COALESCE(event2.notes,' ')||COALESCE(event2.cause,' ')||
			COALESCE(event2.label,' '),' '),'null','' ) -- as eventext
	FROM indiv
	LEFT JOIN event ON event.indiv_id = indiv.indiv_id AND event.type_ = 'DEAT'
	LEFT JOIN event AS event2 ON event2.indiv_id = indiv.indiv_id AND event2.type_ = 'EVEN'
	GROUP BY indiv.indiv_id;

-- ///////////////////////////////////////////////////////////////
-- tragic (run time ~14 min) [run 02May2016, 29952 records]
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

-- ///////////////////////////////////////////////////////////////
-- need to add records to indiv_dist for new indiv records
insert into indiv_dist(indiv_id,odnb_id)
	select indiv_id, odnb from indiv i where i.indiv_id not in (select indiv_id from indiv_dist)
-- none at the moment

-- then fill in fields for new records
-- insert tragedy and trarray fields in indiv_dist (run time 2.5 sec)
-- test: copy indiv_dist to 'temp' schema, clone it back into 'public' --
-- alter table indiv_dist set schema temp;
-- select * into indiv_dist from temp.indiv_dist;

----------
UPDATE indiv_dist
SET trarray =
'['||(
CASE
when LOWER(deathtext) LIKE '%wounds%' OR LOWER(deathtext) LIKE '%battle%' OR LOWER(deathtext) LIKE '%killed in action%' OR LOWER(deathtext) LIKE '%cwgc.org%' then 1
when LOWER(deathtext) LIKE '%hanged%' OR LOWER(deathtext) LIKE '%shot%' OR LOWER(deathtext) LIKE '%executed%' OR LOWER(deathtext) LIKE '%beheaded%' OR LOWER(deathtext) LIKE '%tower hill%' OR LOWER(deathtext) LIKE '%tyburn%' then 1
when LOWER(deathtext) LIKE '%murdered%' OR LOWER(deathtext) LIKE '%stabbed%' OR LOWER(deathtext) LIKE '%suicide%' OR LOWER(deathtext) LIKE '%killed herself%' OR LOWER(deathtext) LIKE '%killed himself%' then 1
else diedyoung
END
)||
','||tragic.trarray||','||
(
CASE
when LOWER(eventext) LIKE '%insane%' OR LOWER(eventext) LIKE '%breakdown%' OR LOWER(eventext) LIKE '%lunatic%' then 1
else 0
END
)||']',

tragedy = total +
(
CASE
when LOWER(deathtext) LIKE '%wounds%' OR LOWER(deathtext) LIKE '%battle%' OR LOWER(deathtext) LIKE '%killed in action%' OR LOWER(deathtext) LIKE '%cwgc.org%' then 1
when LOWER(deathtext) LIKE '%hanged%' OR LOWER(deathtext) LIKE '%shot%' OR LOWER(deathtext) LIKE '%executed%' OR LOWER(deathtext) LIKE '%beheaded%' OR LOWER(deathtext) LIKE '%tower hill%' OR LOWER(deathtext) LIKE '%tyburn%' then 1
when LOWER(deathtext) LIKE '%murdered%' OR LOWER(deathtext) LIKE '%stabbed%' OR LOWER(deathtext) LIKE '%suicide%' OR LOWER(deathtext) LIKE '%killed herself%' OR LOWER(deathtext) LIKE '%killed himself%' then 1
else diedyoung
END
)
+
(
CASE
when LOWER(eventext) LIKE '%insane%' OR LOWER(eventext) LIKE '%breakdown%' OR LOWER(eventext) LIKE '%lunatic%' then 1
else 0
END
)

FROM tragic, trag_text
WHERE trag_text.indiv_id = tragic.indiv_id
AND tragic.indiv_id = indiv_dist.indiv_id;


-- ///////////////////////////////////////////////////////////////
-- put number of children, marriages into indiv_dist
update indiv_dist id set 
  children = coalesce(array_length(ef.children,1),0),
  marriage = coalesce(array_length(ef.spouses,1),0)
  from extfamily ef
	where ef.indiv_id = id.indiv_id;

-- ///////////////////////////////////////////////////////////////
-- odnb_wordcount
-- NOTE: json.odnb in code refers to indiv_dist.odnb, NOT indiv.odnb_id
-- create indiv_dist.odnb_id value for new indivs with odnb_id !!!
update indiv_dist id set odnb_id = i.odnb_id from indiv i where i.indiv_id = id.indiv_id and i.odnb_id is not null;
-- get word count for all odnbers
update indiv_dist id set 
  odnb_wordcount = o.words
  from odnbers o
	where id.odnb_id is not null
	and o.odnb_id = id.odnb_id;


select * from indiv_dist where odnb = -1
-- ///////////////////////////////////////////////////////////////
-- put odnb (distance) into indiv_dist
-- 3627 odnbers at the moment
select odnb_id from indiv where odnb_id is not null

