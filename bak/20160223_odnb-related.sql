-- need to add odnb_id and odnb_wordcount to indiv where applicable
select id.indiv_id, i.fullname, i.birthyear from indiv_dist id 
	join indiv i on id.indiv_id = i.indiv_id
	where id.odnb_id is not null and
	id.indiv_id not in (
select i.indiv_id --, o.odnb_id, o.words --,o.fullname as ofull,i.fullname as ifull, 
	from indiv i
	join odnbers o on (i.surn = o.last or i.marnm = o.last)
	and (i.birthyear between extract(year from o.birth)-1 and extract(year from o.birth) +1)
-- 	AND i.birthyear = extract(year from o.birth) 
	and (i.deathyear between extract(year from o.death)-1 and extract(year from o.death) +1)
-- 	and i.deathyear = extract(year from o.death) 
	and (replace(replace(o.fullname,'[',''),']',''))
		like '%'||substr(replace(replace(i.fullname,'(',''),')',''),1,8)||'%' 
	-- returns 2495
)
-- check against existing
select count(*) from indiv_dist where odnb_id is not null -- 3627
-- several issues
	-- maiden vs. married names
	-- misspellings (Melvill vs Melville
	-- year mismatch (odnb has date ranges 1794/95 = 1794-01-01)
	
select * from odnbers where last='Calder'

-- undirected shortest path
select source,target from o_indiv_path_undirected('I10','I10103',2050,100)



