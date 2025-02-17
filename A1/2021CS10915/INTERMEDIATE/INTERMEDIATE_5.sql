select a.subject_id,a.hadm_id,
coalesce(pr_cnt ,0) as count_procedures,
coalesce(dg_cnt ,0) as count_diagnoses
from hosp.admissions as a

left join (
    select hadm_id,count(*) as pr_cnt
    from hosp.procedures_icd 
    group by hadm_id
) as pr on a.hadm_id=pr.hadm_id

left join (
    select hadm_id,count(*) as dg_cnt
    from hosp.diagnoses_icd 
    group by hadm_id
) as dg on a.hadm_id=dg.hadm_id

where a.hospital_expire_flag=1 and 
a.admission_type='URGENT'
order by subject_id, hadm_id, 
count_procedures desc, count_diagnoses desc;