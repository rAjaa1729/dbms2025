select pt.subject_id 
from hosp.patients as pt
where pt.gender='F' 
and pt.anchor_age>89
order by pt.subject_id;