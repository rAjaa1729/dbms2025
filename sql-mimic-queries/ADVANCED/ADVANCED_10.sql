with I2_patients as(
    select a.subject_id, a.dischtime as d1
    from hosp.admissions as a 
    join hosp.diagnoses_icd as d 
    on a.hadm_id = d.hadm_id and 
    a.subject_id = d.subject_id 

    where d.icd_code like 'I2%'
    and admittime = (
        select min(admittime) from 
        hosp.admissions as aa 
        where aa.subject_id = a.subject_id
    )
),
eligible_patients as (
    select ip.subject_id, aa.hadm_id as h2,(cast(admittime as timestamp)-cast(d1 as timestamp)) as timegap
    from I2_patients as ip 
    join hosp.admissions as aa 
    on ip.subject_id = aa.subject_id 
    where cast(aa.admittime as timestamp) <= cast(d1 as timestamp)+interval '180 days'
    and admittime = (
        select min(admittime) from hosp.admissions as a
        where a.subject_id = aa.subject_id
        and admittime>d1
    )
),
answer as (
    select ep.subject_id , ep.h2 as second_hadm_id,
    to_char(timegap, 'YYYY-MM-DD HH24:MI:SS') as time_gap_between_admissions,
    coalesce(string_agg(t.curr_service,',' order by t.transfertime),'') as services
    from eligible_patients as ep join 
    hosp.services as t on 
    ep.h2 = t.hadm_id
    group by ep.subject_id,ep.h2,ep.timegap
)
select * from answer
order by length(services) desc,
time_gap_between_admissions desc,
subject_id,second_hadm_id;