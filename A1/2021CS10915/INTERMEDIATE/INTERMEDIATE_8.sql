select subject_id, 
avg(to_timestamp(dischtime, 'YYYY-MM-DD HH24:MI:SS')-to_timestamp(admittime, 'YYYY-MM-DD HH24:MI:SS'))
as avg_duration
from hosp.admissions
group by subject_id
order by subject_id