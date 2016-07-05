-- 1) ///////////////////////////////////////////////////////////////
-- trag_text [run 03May2016, 29952 rows; 31 May 29951 rows]
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
  