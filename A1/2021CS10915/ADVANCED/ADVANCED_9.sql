with amlo_filter as (
    select subject_id, hadm_id , count(*) as amp 
    from hosp.prescriptions as pp
    where lower(drug) like 'amlodipine'
    group by subject_id,hadm_id
),
lisi_filter as (
    select subject_id, hadm_id , count(*) as lis
    from hosp.prescriptions as pp
    where lower(drug) like 'lisinopril'
    group by subject_id,hadm_id
),
valid_patients as (
    select coalesce(af.subject_id,lf.subject_id) as subject_id, 
    coalesce(af.hadm_id,lf.hadm_id) as hadm_id,
    (
        case 
        when coalesce(amp,0)>0 and coalesce(lis,0)>0 then 'both'
        when coalesce(amp,0)=0 and coalesce(lis,0)>0 then 'lisinopril'
        when coalesce(amp,0)>0 and coalesce(lis,0)=0 then 'amlodipine'
        end
    ) as drug
    from amlo_filter as af 
    full outer join lisi_filter as lf
    on af.hadm_id = lf.hadm_id
),
service_path as (
    select vp.subject_id, vp.hadm_id, drug,
    array_agg(t.curr_service order by t.transfertime) as services
    from valid_patients as vp join
    hosp.services as t on 
    vp.hadm_id = t.hadm_id
    group by vp.hadm_id, vp.subject_id,drug
)
select * from service_path order by subject_id,hadm_id;