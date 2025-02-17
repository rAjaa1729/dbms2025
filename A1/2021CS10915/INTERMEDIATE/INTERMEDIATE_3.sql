with pr as (
    select prc.caregiver_id, count(*) as pr_c
    from icu.procedureevents as prc
    where prc.caregiver_id is not null
    group by prc.caregiver_id
),
chr as (
    select chrc.caregiver_id, count(*) as chr_c
    from icu.chartevents as chrc
    where chrc.caregiver_id is not null
    group by chrc.caregiver_id
),
dtr as (
    select dtrc.caregiver_id, count(*) as dtr_c
    from icu.datetimeevents as dtrc
    where dtrc.caregiver_id is not null
    group by dtrc.caregiver_id
)
select cg.caregiver_id,
coalesce(pr.pr_c, 0) as procedureevents_count,
coalesce(chr.chr_c, 0) as chartevents_count,
coalesce(dtr.dtr_c, 0) as datetimeevents_count
from icu.caregiver as cg
left join pr on 
cg.caregiver_id = pr.caregiver_id
left join chr on 
cg.caregiver_id = chr.caregiver_id
left join dtr on 
cg.caregiver_id = dtr.caregiver_id
order by cg.caregiver_id;