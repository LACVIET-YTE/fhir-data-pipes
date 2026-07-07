CREATE TABLE IF NOT EXISTS encounter_participant_fact
USING org.apache.spark.sql.jdbc
OPTIONS (
  url 'jdbc:postgresql://fhir-views-db:5432/views',
  dbtable 'encounter_participant_fact',
  user 'admin',
  password 'admin',
  driver 'org.postgresql.Driver'
)
AS SELECT * FROM Encounter_participant_fact_view
;