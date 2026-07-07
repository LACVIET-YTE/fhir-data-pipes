INSERT OVERWRITE TABLE encounter_inpatient_fact
SELECT * FROM Encounter_inpatient_fact_view
;