with recursive
valid_patients as (
    select subject_id, admittime, dischtime
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
connected_component as (
    select node1 as s1, node2 as s2, 2 as no_of_nodes, array[node1, node2] as visited_nodes
    from graph_edges
    where node1 = 10038081

    union all

    select g.node1, g.node2, 1 + no_of_nodes, cc.visited_nodes || g.node2
    from graph_edges g
    join connected_component cc on g.node1 = cc.s2
    where g.node2 <> all (cc.visited_nodes)
)
select max(no_of_nodes) as count
from connected_component;
