
select d.subject_id, 
count(distinct a.hadm_id) as count_admissions,
extract(year from to_timestamp(a.admittime,'YYYY-MM-DD HH24:MI:SS')) AS year

from hosp.admissions as a
join hosp.diagnoses_icd as d on a.hadm_id = d.hadm_id
join hosp.d_icd_diagnoses as diag on d.icd_code = diag.icd_code and d.icd_version=diag.icd_version

where lower(diag.long_title) like '%infection%'
group by d.subject_id,year
having count(distinct a.hadm_id) > 1
order by year, count_admissions desc

;