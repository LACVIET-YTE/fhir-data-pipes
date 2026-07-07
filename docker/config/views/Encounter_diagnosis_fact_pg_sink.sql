CREATE TABLE IF NOT EXISTS encounter_diagnosis_fact
USING org.apache.spark.sql.jdbc
OPTIONS (
  url 'jdbc:postgresql://fhir-views-db:5432/views',
  dbtable 'encounter_diagnosis_fact',
  user 'admin',
  password 'admin',
  driver 'org.postgresql.Driver'
)
AS SELECT * FROM Encounter_diagnosis_fact_view
;