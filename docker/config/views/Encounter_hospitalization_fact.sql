CREATE OR REPLACE VIEW Encounter_hospitalization_fact_view AS
SELECT
  E.id AS EncounterHospitalizationID,
  E.id AS EncounterID,
  E.subject.patientId AS PatientID,
  E.class.code = 'IMP' AS IsInpatientFlag,
  to_timestamp(E.period.start) AS AdmissionDateTime,
  to_timestamp(E.period.end) AS DischargeDateTime,
  CAST(date_format(to_timestamp(E.period.start), 'yyyyMMdd') AS INT) AS AdmissionDateKey,
  CAST(date_format(to_timestamp(E.period.end), 'yyyyMMdd') AS INT) AS DischargeDateKey,
  datediff(to_timestamp(E.period.end), to_timestamp(E.period.start)) AS LengthOfStayDays,
  E.hospitalization.preAdmissionIdentifier.value AS PreAdmissionIdentifierValue,
  E.hospitalization.preAdmissionIdentifier.system AS PreAdmissionIdentifierSystem,
  CASE
    WHEN E.hospitalization.origin.locationId IS NOT NULL THEN 'Location'
    WHEN E.hospitalization.origin.organizationId IS NOT NULL THEN 'Organization'
  END AS OriginReferenceType,
  COALESCE(E.hospitalization.origin.locationId, E.hospitalization.origin.organizationId) AS OriginReferenceID,
  E.hospitalization.origin.display AS OriginDisplay,
  try_element_at(E.hospitalization.admitSource.coding, 1).code AS AdmitSourceCode,
  COALESCE(try_element_at(E.hospitalization.admitSource.coding, 1).display, E.hospitalization.admitSource.text) AS AdmitSourceDisplay,
  try_element_at(E.hospitalization.reAdmission.coding, 1).code AS ReAdmissionCode,
  COALESCE(try_element_at(E.hospitalization.reAdmission.coding, 1).display, E.hospitalization.reAdmission.text) AS ReAdmissionDisplay,
  E.hospitalization.reAdmission IS NOT NULL AS IsReadmissionFlag,
  COALESCE(try_element_at(try_element_at(E.hospitalization.dietPreference, 1).coding, 1).display, try_element_at(E.hospitalization.dietPreference, 1).text) AS DietPreference,
  COALESCE(try_element_at(try_element_at(E.hospitalization.specialCourtesy, 1).coding, 1).display, try_element_at(E.hospitalization.specialCourtesy, 1).text) AS SpecialCourtesy,
  COALESCE(try_element_at(try_element_at(E.hospitalization.specialArrangement, 1).coding, 1).display, try_element_at(E.hospitalization.specialArrangement, 1).text) AS SpecialArrangement,
  CASE
    WHEN E.hospitalization.destination.locationId IS NOT NULL THEN 'Location'
    WHEN E.hospitalization.destination.organizationId IS NOT NULL THEN 'Organization'
  END AS DestinationReferenceType,
  COALESCE(E.hospitalization.destination.locationId, E.hospitalization.destination.organizationId) AS DestinationReferenceID,
  E.hospitalization.destination.display AS DestinationDisplay,
  try_element_at(E.hospitalization.dischargeDisposition.coding, 1).code AS DischargeDispositionCode,
  COALESCE(try_element_at(E.hospitalization.dischargeDisposition.coding, 1).display, E.hospitalization.dischargeDisposition.text) AS DischargeDispositionDisplay,
  E.meta.lastUpdated AS SourceLastUpdated
FROM Encounter AS E
WHERE E.hospitalization IS NOT NULL
;