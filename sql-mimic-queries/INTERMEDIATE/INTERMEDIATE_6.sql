with bmi as(
    select subject_id,(result_value::numeric) as qnt
    from hosp.omr omr 
    where omr.result_name like '%BMI%'
),
valid_pa as (
    select distinct ph1.subject_id
    from hosp.pharmacy as ph1 join
    hosp.pharmacy as ph2 on 
    ph1.subject_id=ph2.subject_id
    and ph1.medication='OxyCODONE (Immediate Release)'
    and ph2.medication='Insulin'
)

select avg(qnt) as avg_BMI
from bmi join valid_pa 
on bmi.subject_id = valid_pa.subject_id;