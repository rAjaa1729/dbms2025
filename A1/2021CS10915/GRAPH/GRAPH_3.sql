with recursive
valid_patients as (
    select subject_id,admittime,dischtime
    from hosp.admissions
    order by admittime
    limit 200
),
graph_edges as (
    select distinct a1.subject_id as node1, a2.subject_id as node2
    from valid_patients as a1
    join valid_patients as a2 
      on a1.subject_id <> a2.subject_id
     and (
         (a1.admittime <= a2.dischtime and a1.admittime >= a2.admittime) 
      or (a2.admittime <= a1.dischtime and a2.admittime >= a1.admittime)
     )
),

shortest_path as (

    select node1, node2, 1 as path_length, ARRAY[node1] as visited_nodes
    from graph_edges
    where node1 = 10038081 

    union all


    select g.node1, g.node2, sp.path_length + 1, sp.visited_nodes || g.node2
    from graph_edges g
    join shortest_path sp on g.node1 = sp.node2
    where g.node2 <> ALL (sp.visited_nodes)  
    and sp.path_length < 200  
)
select min(path_length) as path_length
from shortest_path
where node2 = 10021487;
