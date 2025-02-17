with valid_patients as (

    select *
    from hosp.admissions
    order by admittime asc
    limit 200
),
graph_edges as (
    select distinct
    least(a1.subject_id, a2.subject_id) as subject_id1,
    greatest(a1.subject_id, a2.subject_id) as subject_id2
    from valid_patients as a1
    join valid_patients as a2 
    on a1.subject_id <> a2.subject_id
    and a1.admittime <= a2.dischtime 
    and a2.admittime <= a1.admittime
    join hosp.diagnoses_icd as d1 on a1.hadm_id = d1.hadm_id
    join hosp.diagnoses_icd as d2 
    on a2.hadm_id = d2.hadm_id
    and d1.icd_code = d2.icd_code
    and d1.icd_version = d2.icd_version
)
select subject_id1, subject_id2
from graph_edges
order by subject_id1, subject_id2;
