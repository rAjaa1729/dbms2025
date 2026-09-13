with valid_patients as (
    select *
    from hosp.admissions
    order by admittime
    limit 200
),
graph_edges as (
    select distinct a1.subject_id as node1, a2.subject_id as  node2
    from valid_patients as a1
    join valid_patients as a2 
    on a1.subject_id <> a2.subject_id
    and ((a1.admittime <= a2.dischtime and a1.admittime >= a2.admittime) 
    or (a2.admittime <= a1.dischtime and a2.admittime >= a1.admittime))
)
select case 
         when exists (
           select 1 
           from graph_edges
           where node1 = 10006580 and node2 = 10003400
         ) then 1
         else 0
       end as path_exists;
