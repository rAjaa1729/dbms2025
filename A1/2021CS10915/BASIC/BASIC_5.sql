select count(distinct ad.hadm_id) as count
from hosp.admissions as ad join hosp.emar_detail as em_dt 
on ad.subject_id=em_dt.subject_id
where ad.marital_status <> 'MARRIED' and
em_dt.reason_for_no_barcode='Barcode Damaged';