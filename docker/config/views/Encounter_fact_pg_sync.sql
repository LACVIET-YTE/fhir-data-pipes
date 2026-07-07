INSERT OVERWRITE TABLE encounter_fact
SELECT * FROM Encounter_fact_view
;