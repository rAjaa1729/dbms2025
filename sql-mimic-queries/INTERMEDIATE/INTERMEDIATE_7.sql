with recent_admit as(
    select a.hadm_id,a.subject_id,icd_version,icd_code
    from hosp.admissions as a join 
    hosp.diagnoses_icd as d
    on a.hadm_id=d.hadm_id
    where admittime = (
        select max(admittime)
        from hosp.admissions as temp
        where temp.subject_id = a.subject_id
    )
),
first_admit as(
    select a.hadm_id,a.subject_id,icd_version,icd_code
    from hosp.admissions as a join 
    hosp.diagnoses_icd as d
    on a.hadm_id=d.hadm_id
    where admittime = (
        select min(admittime)
        from hosp.admissions as temp
        where temp.subject_id = a.subject_id
    )
),
true_pt as(
    select distinct t1.subject_id
    from recent_admit as t1 
    join first_admit as t2 on 
    t1.subject_id = t2.subject_id 
    and t1.hadm_id <> t2.hadm_id
    and t1.icd_version = t2.icd_version
    and t1.icd_code = t2.icd_code
)

select p.gender, 
round(100.0 * count(p.subject_id) / (select count(*) from true_pt), 2) as percentage
from hosp.patients as p
join true_pt on p.subject_id = true_pt.subject_id
group by p.gender
order by percentage desc;