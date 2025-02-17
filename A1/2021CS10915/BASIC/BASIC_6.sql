select subject_id,count(stay_id) as count
from icu.icustays as icst
group by icst.subject_id
order by count,subject_id;