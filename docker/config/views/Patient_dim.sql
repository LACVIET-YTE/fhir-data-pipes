CREATE OR REPLACE VIEW Patient_dim_view AS
SELECT P.id AS PatientID,
  PI.value AS IdentifierValue, PI.system AS IdentifierSystem,
  try_element_at(PI.type.coding, 1).code AS IdentifierType,
  P.active AS ActiveFlag,
  PN.text AS PatientName, PN.use AS NameUse, PN.family AS FamilyName, PNG AS GivenName,
  P.gender AS Gender, P.birthDate AS DateOfBirth,
  YEAR(current_date()) - YEAR(P.birthDate) AS Age,
  CASE
    WHEN P.birthDate IS NULL THEN NULL
    WHEN YEAR(current_date()) - YEAR(P.birthDate) < 18 THEN '0-17'
    WHEN YEAR(current_date()) - YEAR(P.birthDate) < 35 THEN '18-34'
    WHEN YEAR(current_date()) - YEAR(P.birthDate) < 50 THEN '35-49'
    WHEN YEAR(current_date()) - YEAR(P.birthDate) < 65 THEN '50-64'
    ELSE '65+'
  END AS AgeGroup,
  P.deceased.Boolean AS DeceasedFlag, P.deceased.dateTime AS DeceasedDate,
  P.multipleBirth.Boolean AS MultipleBirthFlag, P.multipleBirth.Integer AS MultipleBirthOrder,
  try_element_at(filter(P.telecom, PT -> PT.system = 'phone'), 1).value AS Phone,
  try_element_at(filter(P.telecom, PT -> PT.system = 'email'), 1).value AS Email,
  PA.use AS AddressUse, PA.text AS AddressText, PAL AS AddressLine,
  PA.city AS City, PA.district AS District, PA.state AS Province,
  PA.country AS Country, PA.postalCode AS PostalCode,
  try_element_at(P.maritalStatus.coding, 1).code AS MaritalStatusCode,
  P.maritalStatus.text AS MaritalStatusText,
  try_element_at(PCM.language.coding, 1).code AS LanguageCode,
  PCM.language.text AS LanguageText, PCM.preferred AS PreferredLanguageFlag,
  P.managingOrganization.organizationId AS ManagingOrganizationID,
  P.managingOrganization.display AS ManagingOrganizationDisplay,
  PG.practitionerId AS GeneralPractitionerID,
  CASE
    WHEN PG.practitionerId IS NOT NULL THEN 'Practitioner'
    WHEN PG.practitionerRoleId IS NOT NULL THEN 'PractitionerRole'
    WHEN PG.organizationId IS NOT NULL THEN 'Organization'
  END AS GeneralPractitionerType,
  P.meta.lastUpdated AS SourceLastUpdated
FROM Patient AS P LATERAL VIEW OUTER explode(name) AS PN
  LATERAL VIEW OUTER explode(PN.given) AS PNG
  LATERAL VIEW OUTER explode(identifier) AS PI
  LATERAL VIEW OUTER explode(address) AS PA
  LATERAL VIEW OUTER explode(PA.line) AS PAL
  LATERAL VIEW OUTER explode(communication) AS PCM
  LATERAL VIEW OUTER explode(generalPractitioner) AS PG
;