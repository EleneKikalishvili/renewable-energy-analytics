/* ======================================================================
   File    : 00_run_all.sql
   Purpose : Builds the renewables_project database from scratch using psql.
             Run from the /database folder:
               psql -U youruser -d yourdb -f 00_run_all.sql
   Author  : Elene Kikalishvili
   Date    : 2025-06-01
   ====================================================================== */

-- All steps are run in order using psql's \i command.
-- If not using psql, see README for manual instructions.


\set ON_ERROR_STOP 1
\pset pager off
\timing

\echo '=== Starting full build ==='

/* ------------------------------------------------------------------ */
/* Clean slate                                                         */
/* ------------------------------------------------------------------ */
\echo '--- Dropping existing schema (if any)…'
DROP SCHEMA IF EXISTS renewables_project CASCADE;

/* ------------------------------------------------------------------ */
/* DDL: schema, enums, tables, indexes, staging                        */
/* ------------------------------------------------------------------ */
\echo '--- Creating schema and objects…'
BEGIN;
\i ./ddl/01_create_schema.sql
\i ./ddl/02_create_enums.sql
\i ./ddl/03_create_dim_tables.sql
\i ./ddl/04_create_lookups.sql
\i ./ddl/05_create_fact_tables.sql
\i ./ddl/06_create_indexes.sql
\i ./ddl/07_create_staging_tables.sql
COMMIT;

/* ------------------------------------------------------------------ */
/* DML: load data into staging, then into dims/lookups/facts           */
/* ------------------------------------------------------------------ */
\echo '--- Loading raw data into staging…'
BEGIN;
\i ./dml/08_copy_to_staging.sql
COMMIT;

\echo '--- Populating dimension tables…'
BEGIN;
\i ./dml/09_insert_dim_tables.sql
COMMIT;

\echo '--- Populating lookup tables…'
BEGIN;
\i ./dml/10_insert_lookup_tables.sql
COMMIT;

\echo '--- Populating fact tables…'
BEGIN;
\i ./dml/11_insert_fact_tables.sql
COMMIT;

/* ------------------------------------------------------------------ */
/* Optional cleanup                                                    */
/* ------------------------------------------------------------------ */
\echo '--- Dropping staging tables…'
BEGIN;
\i ./dml/12_drop_staging.sql
COMMIT;

\echo '=== Build finished successfully! ==='