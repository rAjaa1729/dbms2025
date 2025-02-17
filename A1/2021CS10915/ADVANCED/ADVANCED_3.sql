with patients as (   
    select p.hadm_id, p.subject_id 
    from hosp.procedures_icd p
    join hosp.diagnoses_icd d on p.hadm_id = d.hadm_id and p.subject_id = d.subject_id
    where d.icd_code like 'T81%' and p.hadm_id is not null
    group by p.hadm_id, p.subject_id
    having count(distinct p.icd_code) > 1
),
valid_patient_id as (
    select distinct subject_id 
    from patients
),
patient_hadmid as (
    select a.subject_id , a.hadm_id
    from valid_patient_id as p join hosp.admissions as a 
    on p.subject_id = a.subject_id 
),
patient_hmid_transfer_count as (
    select a.subject_id , a.hadm_id , coalesce(count(*),0) as ct 
    from patient_hadmid as a 
    left join hosp.transfers as t
    on t.hadm_id = a.hadm_id
    where t.hadm_id is not null
    group by a.subject_id,a.hadm_id
),
avg_transfer_patient as (
    select temp.subject_id ,avg(ct) as avg
    from patient_hmid_transfer_count as temp
    group by subject_id
),
avg_transfer as (
    select avg(ct) as  overall_avg_transfer from 
    patient_hmid_transfer_count
),
valid_patients as (
    select a.subject_id,a.avg
    from avg_transfer_patient a
    cross join avg_transfer b
    where a.avg >= b.overall_avg_transfer
)


select vp.subject_id,
count(distinct icd_code) as distinct_procedures_count,
avg as average_transfers
from valid_patients as vp join 
hosp.procedures_icd as d
on vp.subject_id=d.subject_id
group by vp.subject_id,vp.avg
order by average_transfers desc, distinct_procedures_count Desc,  subject_id;
