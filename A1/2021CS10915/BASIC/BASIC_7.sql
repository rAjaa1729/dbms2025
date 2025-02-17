select pt.subject_id as subject_id,
max(ad.hadm_id) as latest_hadm_id,
pt.dod as dod 
from hosp.patients as pt join hosp.admissions as ad
on pt.subject_id=ad.subject_id
where pt.dod is not NULL
group by pt.subject_id,pt.dod
order by subject_id