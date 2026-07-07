INSERT OVERWRITE TABLE encounter_diagnosis_fact
SELECT * FROM Encounter_diagnosis_fact_view
;