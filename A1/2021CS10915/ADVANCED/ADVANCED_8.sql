with i10_patient as (
    select distinct a.subject_id,a.admittime
    from hosp.admissions as a 
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id
    where d.icd_code like 'I10%'
),
i50_patient as (
    select distinct a.subject_id,a.admittime
    from hosp.admissions as a 
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id
    where d.icd_code like 'I50%'
),
valid_i10i50_patient as (
    select distinct ee.subject_id
    from i10_patient as ee 
    join i50_patient as nn 
    on ee.subject_id = nn.subject_id 
    where (ee.admittime = nn.admittime)
    or nn.admittime = ( select min(admittime)
                        from hosp.admissions as a
                        where a.admittime>ee.admittime
                        and ee.subject_id = a.subject_id
                      )
),
i10timeline as (
    select pp.subject_id ,
    (   select min(admittime)
        from hosp.admissions as a 
        join hosp.diagnoses_icd as d 
        on a.hadm_id = d.hadm_id 
        where a.subject_id = pp.subject_id 
        and d.icd_code like 'I10%'
    ) as i10,
    (   select max(admittime)
        from hosp.admissions as a 
        join hosp.diagnoses_icd as d 
        on a.hadm_id = d.hadm_id 
        where a.subject_id = pp.subject_id 
        and d.icd_code like 'I50%'
    ) as i50
    from valid_i10i50_patient as pp 
),
eligible_patients as(
    select tt.subject_id, hadm_id from 
    i10timeline as tt join 
    hosp.admissions as aa on 
    tt.subject_id = aa.subject_id 
    where (
        select count(*) from hosp.admissions  as a 
        where a.subject_id = tt.subject_id 
        and a.admittime>tt.i10 and 
        a.admittime < tt.i50
    ) >= 2
    and aa.admittime>tt.i10 
    and aa.admittime < tt.i50
)

select  distinct ee.subject_id, ee.hadm_id as admission_id,drug
from eligible_patients as ee 
join hosp.prescriptions as pp
on pp.hadm_id = ee.hadm_id
order by ee.subject_id asc,
ee.hadm_id asc, drug;
