with patient_first_admit as (
    select distinct a.subject_id,admittime
    from hosp.admissions as a
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id
    join hosp.d_icd_diagnoses as diag
    on diag.icd_version=d.icd_version and
    diag.icd_code = d.icd_code
    where admittime = (
        select min(admittime) from
        hosp.admissions as temp
        where temp.subject_id = a.subject_id
    ) 
    and 
        lower(diag.long_title) like '%kidney%'
    and (
        select count(*) from
        hosp.admissions as temp
        where temp.subject_id = a.subject_id
    ) > 1
    order by admittime desc
    limit 100
)
select subject_id from patient_first_admit;