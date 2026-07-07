CREATE OR REPLACE VIEW Encounter_participant_fact_view AS
SELECT
  concat(E.id, '-', CAST(PPos AS STRING)) AS EncounterParticipantID,
  E.id AS EncounterID,
  try_element_at(try_element_at(EP.type, 1).coding, 1).code AS ParticipantTypeCode,
  try_element_at(try_element_at(EP.type, 1).coding, 1).system AS ParticipantTypeSystem,
  COALESCE(try_element_at(try_element_at(EP.type, 1).coding, 1).display, try_element_at(EP.type, 1).text) AS ParticipantTypeDisplay,
  to_timestamp(EP.period.start) AS ParticipantStartTime,
  to_timestamp(EP.period.end) AS ParticipantEndTime,
  (unix_timestamp(to_timestamp(EP.period.end)) - unix_timestamp(to_timestamp(EP.period.start))) / 60 AS ParticipantDurationMinutes,
  CASE
    WHEN EP.individual.practitionerId IS NOT NULL THEN 'Practitioner'
    WHEN EP.individual.practitionerRoleId IS NOT NULL THEN 'PractitionerRole'
    WHEN EP.individual.relatedPersonId IS NOT NULL THEN 'RelatedPerson'
  END AS IndividualReferenceType,
  EP.individual.practitionerId AS PractitionerID,
  EP.individual.practitionerRoleId AS PractitionerRoleID,
  EP.individual.relatedPersonId AS RelatedPersonID,
  EP.individual.display AS ParticipantDisplay,
  try_element_at(try_element_at(EP.type, 1).coding, 1).code IN ('PPRF', 'ATND') AS IsPrimaryParticipantFlag,
  E.meta.lastUpdated AS SourceLastUpdated
FROM Encounter AS E
  LATERAL VIEW posexplode(E.participant) AS PPos, EP
;