select pharmacy_id 
from hosp.pharmacy
where pharmacy_id not in 
(select pharmacy_id from hosp.prescriptions)
order by pharmacy_id;