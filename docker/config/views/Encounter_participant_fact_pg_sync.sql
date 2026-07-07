INSERT OVERWRITE TABLE encounter_participant_fact
SELECT * FROM Encounter_participant_fact_view
;