CREATE OR REPLACE VIEW Encounter_inpatient_fact_view AS
WITH inpatient AS (
  SELECT
    EF.EncounterID,
    EF.PatientID,
    EF.EncounterStatus,
    EF.EncounterClassCode,
    EF.EncounterClassDisplay,
    EF.ServiceProviderOrganizationID,
    EF.PrimaryLocationID,
    EF.CheckInDateKey AS AdmitDateKey,
    to_date(EF.CheckInTime) AS AdmitDate,
    EF.CheckInTime AS AdmitDateTime,
    CAST(date_format(EF.EncounterEndTime, 'yyyyMMdd') AS INT) AS DischargeDateKey,
    to_date(EF.EncounterEndTime) AS DischargeDate,
    EF.EncounterEndTime AS DischargeDateTime,
    EF.EncounterDurationDays AS LengthOfStayDays,
    EF.EncounterDurationMinutes / 60 AS LengthOfStayHours,
    EF.AppointmentID,
    EF.IsEmergencyFlag,
    EF.IsReadmission30dFlag,
    EF.SourceLastUpdated,
    try_element_at(E.hospitalization.admitSource.coding, 1).code AS AdmitSourceCode,
    COALESCE(try_element_at(E.hospitalization.admitSource.coding, 1).display, E.hospitalization.admitSource.text) AS AdmitSourceDisplay,
    try_element_at(E.hospitalization.dischargeDisposition.coding, 1).code AS DischargeDispositionCode,
    COALESCE(try_element_at(E.hospitalization.dischargeDisposition.coding, 1).display, E.hospitalization.dischargeDisposition.text) AS DischargeDispositionDisplay,
    CASE
      WHEN E.hospitalization.origin.locationId IS NOT NULL THEN 'Location'
      WHEN E.hospitalization.origin.organizationId IS NOT NULL THEN 'Organization'
    END AS OriginReferenceType,
    COALESCE(E.hospitalization.origin.locationId, E.hospitalization.origin.organizationId) AS OriginReferenceID,
    CASE
      WHEN E.hospitalization.destination.locationId IS NOT NULL THEN 'Location'
      WHEN E.hospitalization.destination.organizationId IS NOT NULL THEN 'Organization'
    END AS DestinationReferenceType,
    COALESCE(E.hospitalization.destination.locationId, E.hospitalization.destination.organizationId) AS DestinationReferenceID,
    E.hospitalization.reAdmission IS NOT NULL AS IsReadmissionFlag
  FROM Encounter_fact_view AS EF
    JOIN Encounter AS E ON E.id = EF.EncounterID
  WHERE EF.IsInpatientFlag
),
prev_discharge AS (
  SELECT EncounterID,
    LAG(DischargeDateTime) OVER (PARTITION BY PatientID ORDER BY AdmitDateTime) AS PreviousDischargeDate
  FROM inpatient
)
SELECT
  i.EncounterID AS InpatientEncounterID,
  i.EncounterID AS EncounterID,
  i.PatientID AS PatientID,
  i.EncounterStatus AS EncounterStatus,
  i.EncounterClassCode AS EncounterClassCode,
  i.EncounterClassDisplay AS EncounterClassDisplay,
  i.ServiceProviderOrganizationID AS ServiceProviderOrganizationID,
  i.PrimaryLocationID AS PrimaryLocationID,
  i.PrimaryLocationID AS PrimaryBedID,
  i.AdmitDateKey AS AdmitDateKey,
  i.AdmitDate AS AdmitDate,
  i.AdmitDateTime AS AdmitDateTime,
  i.DischargeDateKey AS DischargeDateKey,
  i.DischargeDate AS DischargeDate,
  i.DischargeDateTime AS DischargeDateTime,
  i.LengthOfStayDays AS LengthOfStayDays,
  i.LengthOfStayHours AS LengthOfStayHours,
  i.AdmitSourceCode AS AdmitSourceCode,
  i.AdmitSourceDisplay AS AdmitSourceDisplay,
  i.DischargeDispositionCode AS DischargeDispositionCode,
  i.DischargeDispositionDisplay AS DischargeDispositionDisplay,
  i.OriginReferenceType AS OriginReferenceType,
  i.OriginReferenceID AS OriginReferenceID,
  i.DestinationReferenceType AS DestinationReferenceType,
  i.DestinationReferenceID AS DestinationReferenceID,
  i.AppointmentID IS NOT NULL AS IsPlannedAdmissionFlag,
  (i.IsEmergencyFlag OR i.AdmitSourceCode = 'emd') AS IsEmergencyAdmissionFlag,
  i.DischargeDateTime IS NOT NULL AS IsDischargedFlag,
  (i.DischargeDateTime IS NULL AND i.EncounterStatus = 'in-progress') AS IsCurrentInpatientFlag,
  i.IsReadmissionFlag AS IsReadmissionFlag,
  i.IsReadmission30dFlag AS IsReadmission30dFlag,
  pd.PreviousDischargeDate AS PreviousDischargeDate,
  datediff(i.AdmitDateTime, pd.PreviousDischargeDate) AS DaysSincePreviousDischarge,
  i.SourceLastUpdated AS SourceLastUpdated
FROM inpatient AS i
  LEFT JOIN prev_discharge AS pd ON pd.EncounterID = i.EncounterID
;