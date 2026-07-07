CREATE OR REPLACE VIEW Encounter_fact_view AS
WITH base AS (
  SELECT
    E.id AS EncounterID,
    try_element_at(E.identifier, 1).value AS IdentifierValue,
    try_element_at(E.identifier, 1).system AS IdentifierSystem,
    E.subject.patientId AS PatientID,
    E.status AS EncounterStatus,
    E.class.code AS EncounterClassCode,
    E.class.system AS EncounterClassSystem,
    E.class.display AS EncounterClassDisplay,
    try_element_at(try_element_at(E.type, 1).coding, 1).code AS EncounterTypeCode,
    COALESCE(try_element_at(try_element_at(E.type, 1).coding, 1).display, try_element_at(E.type, 1).text) AS EncounterTypeDisplay,
    try_element_at(E.serviceType.coding, 1).code AS ServiceTypeCode,
    COALESCE(try_element_at(E.serviceType.coding, 1).display, E.serviceType.text) AS ServiceTypeDisplay,
    try_element_at(E.priority.coding, 1).code AS PriorityCode,
    COALESCE(try_element_at(E.priority.coding, 1).display, E.priority.text) AS PriorityDisplay,
    CAST(date_format(to_timestamp(E.period.start), 'yyyyMMdd') AS INT) AS CheckInDateKey,
    to_timestamp(E.period.start) AS CheckInTime,
    to_timestamp(E.period.end) AS EncounterEndTime,
    (unix_timestamp(to_timestamp(E.period.end)) - unix_timestamp(to_timestamp(E.period.start))) / 60 AS EncounterDurationMinutes,
    datediff(to_timestamp(E.period.end), to_timestamp(E.period.start)) AS EncounterDurationDays,
    E.serviceProvider.organizationId AS ServiceProviderOrganizationID,
    E.serviceProvider.display AS ServiceProviderOrganizationDisplay,
    try_element_at(E.location, 1).location.locationId AS PrimaryLocationID,
    try_element_at(E.location, 1).location.display AS PrimaryLocationDisplay,
    try_element_at(filter(E.participant, PP -> PP.individual.practitionerId IS NOT NULL), 1).individual.practitionerId AS PrimaryPractitionerID,
    try_element_at(filter(E.participant, PP -> PP.individual.practitionerRoleId IS NOT NULL), 1).individual.practitionerRoleId AS PrimaryPractitionerRoleID,
    try_element_at(filter(E.participant, PP -> PP.individual.practitionerId IS NOT NULL OR PP.individual.practitionerRoleId IS NOT NULL), 1).period.start AS PrimaryPractitionerStartTime,
    try_element_at(E.appointment, 1).appointmentId AS AppointmentID,
    try_element_at(try_element_at(E.reasonCode, 1).coding, 1).code AS ReasonCode,
    COALESCE(try_element_at(try_element_at(E.reasonCode, 1).coding, 1).display, try_element_at(E.reasonCode, 1).text) AS ReasonDisplay,
    CASE
      WHEN try_element_at(E.reasonReference, 1).conditionId IS NOT NULL THEN 'Condition'
      WHEN try_element_at(E.reasonReference, 1).procedureId IS NOT NULL THEN 'Procedure'
      WHEN try_element_at(E.reasonReference, 1).observationId IS NOT NULL THEN 'Observation'
      WHEN try_element_at(E.reasonReference, 1).immunizationRecommendationId IS NOT NULL THEN 'ImmunizationRecommendation'
    END AS ReasonReferenceType,
    COALESCE(
      try_element_at(E.reasonReference, 1).conditionId,
      try_element_at(E.reasonReference, 1).procedureId,
      try_element_at(E.reasonReference, 1).observationId,
      try_element_at(E.reasonReference, 1).immunizationRecommendationId
    ) AS ReasonReferenceID,
    E.partOf.encounterId AS PartOfEncounterID,
    E.class.code = 'IMP' AS IsInpatientFlag,
    E.class.code = 'EMER' AS IsEmergencyFlag,
    E.meta.lastUpdated AS SourceLastUpdated
  FROM Encounter AS E
),
patient_order AS (
  SELECT EncounterID,
    ROW_NUMBER() OVER (PARTITION BY PatientID ORDER BY CheckInTime) = 1 AS IsNewPatientFlag
  FROM base
),
inpatient_readmission AS (
  SELECT EncounterID,
    CASE
      WHEN LAG(EncounterEndTime) OVER (PARTITION BY PatientID ORDER BY CheckInTime) IS NOT NULL
        AND datediff(CheckInTime, LAG(EncounterEndTime) OVER (PARTITION BY PatientID ORDER BY CheckInTime)) BETWEEN 0 AND 30
      THEN TRUE
      ELSE FALSE
    END AS IsReadmission30dFlag
  FROM base
  WHERE IsInpatientFlag
)
SELECT b.*, po.IsNewPatientFlag, COALESCE(ir.IsReadmission30dFlag, FALSE) AS IsReadmission30dFlag
FROM base AS b
  LEFT JOIN patient_order AS po ON po.EncounterID = b.EncounterID
  LEFT JOIN inpatient_readmission AS ir ON ir.EncounterID = b.EncounterID
;