-- death date nonsense
-- indiv deaths coalesce deathyear, deatabt, dest
-- dest is set to 2017 for ~1750 people (was 2013)
-- don't know why, but computation of the bio box birth-death string depends on living people
-- having a dest value of 2017
-- so when a death date is add, the dest value need to become NULL

select indiv_id, fullname into z_dest_changed from indiv where dest = 2013 order by surn;
update indiv set dest = 2017 where dest = 2013;
-- fix Christopher Lee
update indiv set dest = null where indiv_id = 'I10103'