(
select distinct icd_code,icd_version
from hosp.procedures_icd
intersect
select distinct icd_code,icd_version
from hosp.diagnoses_icd
)

order by icd_code,icd_version; 