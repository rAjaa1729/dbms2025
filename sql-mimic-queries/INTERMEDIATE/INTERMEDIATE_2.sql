select avg(to_timestamp(ad.dischtime, 'YYYY-MM-DD HH24:MI:SS')-to_timestamp(ad.admittime, 'YYYY-MM-DD HH24:MI:SS'))
as avg_duration
from hosp.admissions as ad 
join hosp.diagnoses_icd as did
on ad.hadm_id=did.hadm_id
where icd_code='4019' and icd_version=9; 