select  count(distinct ad.subject_id) as count,
extract(year from to_timestamp(ad.admittime, 'YYYY-MM-DD HH24:MI:SS')) as year
from hosp.admissions as ad
group by year
order by count desc,year
limit 5;