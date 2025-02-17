with transfer_counts as (
    select subject_id, hadm_id, count(*) as transfer_count
    from hosp.transfers
    where hadm_id is not null
    group by subject_id, hadm_id
),
longest_transfer_patients as (
    select t.subject_id, t.hadm_id
    from transfer_counts t
    where t.transfer_count = (
        select max(transfer_count) as max_count 
        from transfer_counts
    )
    order by t.hadm_id
),
patients as (
    select distinct subject_id 
    from longest_transfer_patients
),
valid_patients as (
    select a.subject_id , a.hadm_id 
    from patients as p 
    join hosp.admissions as a 
    on p.subject_id = a.subject_id 
),
answer as (
    select t.subject_id, 
        t.hadm_id, 
        string_agg(tr.transfer_id::text, ', ' order by tr.intime) as transfers
    from hosp.transfers tr
    join valid_patients t on tr.subject_id = t.subject_id and tr.hadm_id = t.hadm_id
    group by t.subject_id, t.hadm_id
    order by count(distinct transfer_id) asc ,t.hadm_id asc
)
SELECT subject_id, hadm_id,
       '{' || REPLACE(TRIM(BOTH '{}' FROM transfers::TEXT), ',', ', ') || '}' AS transfers
FROM answer;

