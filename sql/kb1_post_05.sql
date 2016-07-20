-- 5) ///////////////////////////////////////////////////////////////
-- indiv_events (indiv_d, particip_array)
-- TODO: why are year values wierd? does it matter?
-- this gets all events and their participonts, use array_agg per indiv_id
-- [29937 existing; run 03May2016, 29952] <- 15 new records but only 14 new INDIVs
DROP table bak.indiv_events;
select * into bak.indiv_events from indiv_events;
delete from indiv_events;
insert into indiv_events(indiv_id, particip_array)
  with y as (
  with z as ( select e.recno AS event_id,
      array_accum(p.actor_id) as particip_array
      from event e, particip p where e.recno = p.event_id group by e.recno
      order by event_id )
    select  e.type_ as eventtype, e.label as eventlabel, e.place_text as eventplace,
    period_text as eventdate, e.place_id AS place,
    coalesce(year,year_abt,year_est,-1) as Year,
    case when(year_abt is not null OR year_est is not null) then 'roughly'
         when year > 0 then 'known'
         else ''
    end as accuracy,
    z.particip_array as actor
    from z join event e on z.event_id = e.recno
    )
    select i.indiv_id,
    '['||
    array_to_string(
    array_agg('{"eventtype":"'||y.eventtype||'","eventlabel":"'||y.eventlabel||
      '","eventplace":"'||coalesce(y.eventplace,'')||'","eventdate":"'||coalesce(y.eventdate,'')||
      case when y.place IS null then '"'
           ELSE '","place":'||coalesce(y.place::text,'""')
           end ||
      case when i.birthyear IS null then ''
           ELSE ',"year":'||(y.year-i.birthyear) -- age at event if birth known
           end ||

      ',"accuracy":"'||coalesce(y.accuracy,'')||
      '","actor":'||'["'||array_to_string(y.actor,'","')||'"]}'),',')||
    ']' -- as particip_array
    from indiv i join y on i.indiv_id = any(y.actor)
    group by i.indiv_id order by indiv_id -- limit 300
