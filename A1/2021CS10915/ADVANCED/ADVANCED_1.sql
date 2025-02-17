with distinct_drug_set_count as (
    select subject_id, count(distinct drug_set) as count_distinct_drug_set,
    count(distinct hadm_id) as admission_count 
    from 
    (
        select a.hadm_id,a.subject_id, 
        array_agg(distinct drug order by drug) as drug_set
        from hosp.admissions as a 
        left join hosp.prescriptions as p 
        on a.hadm_id = p.hadm_id
        and a.subject_id = p.subject_id
        group by a.subject_id,a.hadm_id
    ) as temp
    group by subject_id
    having count(distinct hadm_id)>2
),
distinct_diag_set_count as (
    select subject_id, count(distinct diag_set) as count_distinct_diag_set,
    count(distinct hadm_id) as admission_count
    from 
    (
        select a.subject_id, a.hadm_id, 
        array_agg(distinct icd_code order by icd_code) as diag_set
        from hosp.admissions as a
        left join hosp.diagnoses_icd d
        on a.hadm_id = d.hadm_id 
        and a.subject_id = d.subject_id
        group by a.subject_id,a.hadm_id
    ) as temp
    group by subject_id
    having count(distinct hadm_id)>2
)

select drug.subject_id, drug.admission_count as total_admissions,
coalesce(diag.count_distinct_diag_set,0) as num_distinct_diagnoses_set_count,
coalesce(drug.count_distinct_drug_set,0) as num_distinct_medications_set_count

from distinct_drug_set_count as drug
full outer join distinct_diag_set_count as diag
on drug.subject_id = diag.subject_id    

where coalesce(drug.count_distinct_drug_set,0) >= 3 
or coalesce(diag.count_distinct_diag_set,0) >= 3

order by total_admissions desc, num_distinct_diagnoses_set_count desc, subject_id asc;