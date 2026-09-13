with input_fluid as (
    select distinct stay_id, subject_id,sum(amount) as amount
    from icu.inputevents 
    where amountuom = 'ml'
    group by stay_id,subject_id
),
output_fluid as (
    select distinct stay_id, subject_id,sum(value) as amount
    from icu.outputevents 
    where valueuom = 'ml'
    group by stay_id,subject_id
),
fluid_balance as (
    select distinct coalesce(i.subject_id, o.subject_id) as subject_id
    from input_fluid as i
    full outer join 
    output_fluid as o
    on i.stay_id = o.stay_id and i.subject_id = o.subject_id
    where abs(coalesce(i.amount,0)-coalesce(o.amount,0))>2000
),
inputevents as (
    select distinct i.subject_id,i.stay_id,itemid as item_id,'input' as input_or_output
    from 
    fluid_balance as f join 
    icu.inputevents as i on
    i.subject_id = f.subject_id 
),
outputevents as (
    select distinct o.subject_id,o.stay_id,itemid as item_id,'output' as input_or_output
    from 
    fluid_balance as f join
    icu.outputevents as o on
    o.subject_id = f.subject_id
),
answer as (
    select * from inputevents 
    union all
    select * from outputevents
)
select distinct subject_id,stay_id,item_id,input_or_output, abbreviation as description
from answer as a join 
icu.d_items d on 
a.item_id = d.itemid
order by subject_id,stay_id,input_or_output;