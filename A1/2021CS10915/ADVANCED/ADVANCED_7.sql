with ee_patient as (
    select distinct a.subject_id,a.admittime
    from hosp.admissions as a 
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id
    where d.icd_code like 'E10%'
    or d.icd_code like 'E11%'
),
nn_patient as (
    select distinct a.subject_id,a.admittime
    from hosp.admissions as a 
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id
    where d.icd_code like 'N18%'
),
valid_patient as (
    select distinct ee.subject_id
    from ee_patient as ee 
    join nn_patient as nn 
    on ee.subject_id = nn.subject_id 
    where (ee.admittime = nn.admittime)
    or nn.admittime = ( select min(admittime)
                        from hosp.admissions 
                        where admittime>ee.admittime
                      )
),
diag_code as (
    select distinct p.subject_id,hadm_id as admission_id,
    'diagnoses' as diagnoses_or_procedure,
    icd_code
    from valid_patient as p join 
    hosp.diagnoses_icd as d on 
    p.subject_id = d.subject_id
),
proc_code as (
    select distinct p.subject_id,hadm_id as admission_id,
    'procedures' as diagnoses_or_procedure,
    icd_code
    from valid_patient as p join 
    hosp.procedures_icd as d on 
    p.subject_id = d.subject_id
),
answers as (
    select * from proc_code
    union all 
    select * from diag_code
)
select * from answers
order by
subject_id asc, admission_id asc, icd_code asc, 
diagnoses_or_procedure asc;
