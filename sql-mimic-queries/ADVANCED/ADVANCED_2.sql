with antibiotic_check as (
    select subject_id , hadm_id , 
    count(distinct micro_specimen_id) as resistant_antibiotic_count
    from hosp.microbiologyevents
    where hadm_id is not null 
    and interpretation = 'R'
    group by subject_id,hadm_id
    having count(distinct micro_specimen_id)>1
),
icu_stay_duration_mortality_check as (
    select a.hadm_id, a.subject_id, 
    coalesce(round(sum(extract(epoch 
    from (cast(outtime as timestamp) - cast(intime as timestamp))) / 3600)::numeric, 2), 0) as stay_length,
    (case when discharge_location = 'DIED' then 1 else 0 end) as died_in_hospital

    from hosp.admissions as a 
    left join icu.icustays as icu
    on a.hadm_id = icu.hadm_id

    group by a.hadm_id, a.subject_id,a.discharge_location
)

select at.subject_id, at.hadm_id,
resistant_antibiotic_count,
stay_length as icu_length_of_stay_hours,
died_in_hospital 
from antibiotic_check as at 
join icu_stay_duration_mortality_check as icu
on at.hadm_id = icu.hadm_id

order by died_in_hospital desc, 
resistant_antibiotic_count desc, 
icu_length_of_stay_hours desc, 
at.subject_id asc, at.hadm_id asc;