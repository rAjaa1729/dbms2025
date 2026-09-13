select distinct hcpcs_cd, short_description
from hosp.hcpcsevents 
where lower(short_description) like '%hospital observation%'
order by hcpcs_cd,short_description;