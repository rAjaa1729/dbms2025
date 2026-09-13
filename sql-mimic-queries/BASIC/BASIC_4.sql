select em.enter_provider_id as enter_provider_id,
count(distinct em.medication) as count
from hosp.emar as em
where em.enter_provider_id is not NULL
group by enter_provider_id
order by count desc;