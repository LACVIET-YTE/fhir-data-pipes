INSERT OVERWRITE TABLE patient_dim
SELECT * FROM Patient_dim_view
;