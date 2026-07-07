CREATE OR REPLACE VIEW Encounter_diagnosis_fact_view AS
SELECT
  C.id AS EncounterDiagnosisID,
  C.encounter.encounterId AS EncounterID,
  CAST('Condition' AS STRING) AS DiagnosisReferenceType,
  C.id AS DiagnosisReferenceID,
  C.id AS ConditionID,
  CAST(NULL AS STRING) AS ProcedureID,
  concat(try_element_at(C.code.coding, 1).system, '|', try_element_at(C.code.coding, 1).code) AS ConditionKey,
  try_element_at(C.code.coding, 1).code AS ConditionCode,
  try_element_at(C.code.coding, 1).system AS ConditionSystem,
  COALESCE(try_element_at(C.code.coding, 1).display, C.code.text) AS ConditionDisplay,
  CAST(NULL AS STRING) AS DiagnosisUseCode,
  CAST(NULL AS STRING) AS DiagnosisUseDisplay,
  CAST(NULL AS STRING) AS DiagnosisType,
  CAST(NULL AS INT) AS DiagnosisRank,
  CAST(NULL AS BOOLEAN) AS IsPrimaryDiagnosisFlag,
  try_element_at(E.account, 1).accountId AS AccountID,
  E.meta.lastUpdated AS SourceLastUpdated
FROM Condition AS C
  JOIN Encounter AS E ON E.id = C.encounter.encounterId
;