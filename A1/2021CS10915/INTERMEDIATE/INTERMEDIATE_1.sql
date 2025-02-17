with temp as 
(
    select pt.subject_id as id,
    min(ad.admittime) as adtime,
    pt.dod as dod
    from hosp.patients as pt join hosp.admissions as ad
    on pt.subject_id=ad.subject_id
    where pt.dod is not NULL
    group by pt.subject_id,pt.dod
)

select ad.subject_id,hadm_id, dod 
from hosp.admissions as ad join temp 
on ad.subject_id=temp.id
where ad.admittime = temp.adtime
order by subject_id;