with patients_hmid_pair as (
    select  distinct a.hadm_id , a.subject_id,(min(chartdate)::date+ time '00:00:00')::timestamp as first_procedure
    from hosp.admissions as a join 
    hosp.procedures_icd as pr 
    on a.hadm_id=pr.hadm_id
    where pr.icd_code like '0%' or pr.icd_code like '1%' or pr.icd_code like '2%'
    group by a.hadm_id,a.subject_id
),
consecutive_medi_check as (
    select distinct p.subject_id, p.hadm_id
    from hosp.procedures_icd as p
    join hosp.prescriptions as p1 on
    p.hadm_id = p1.hadm_id 

    where p1.starttime::date =  p.chartdate::date
    or p1.starttime::date = (p.chartdate::date + interval '1 day')
),
multi_medi_check as (
    select distinct hadm_id,subject_id,max(starttime)::timestamp as mx_medi
    from hosp.prescriptions as pp
    group by hadm_id,subject_id
    having count(distinct pp.drug)>1
),
valid_patients as (
    select distinct pp.hadm_id,pp.subject_id,(mx_medi-first_procedure) as time_gap
    from patients_hmid_pair as pp join 
    consecutive_medi_check cc 
    on cc.hadm_id = pp.hadm_id
    join multi_medi_check as mm 
    on cc.hadm_id = mm.hadm_id
)

select vp.subject_id,vp.hadm_id,
(   
    select count(distinct icd_code) from hosp.diagnoses_icd as dd
    where dd.hadm_id = vp.hadm_id
) as distinct_diagnoses,
(   
    select count(distinct icd_code) from hosp.procedures_icd as pp
    where pp.hadm_id = vp.hadm_id
) as distinct_procedures,
to_char(time_gap, 'YYYY-MM-DD HH24:MI:SS') as time_gap
from valid_patients as vp 
order by distinct_diagnoses desc, 
distinct_procedures desc, time_gap asc, subject_id asc,
hadm_id asc;