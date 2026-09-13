select  ad.hadm_id as hadm_id,
pt.gender as gender,
(to_timestamp(ad.dischtime, 'YYYY-MM-DD HH24:MI:SS')-to_timestamp(ad.admittime, 'YYYY-MM-DD HH24:MI:SS')) as duration
from hosp.admissions as ad join hosp.patients as pt 
on ad.subject_id=pt.subject_id
where ad.dischtime is not NULL
order by duration,hadm_id;