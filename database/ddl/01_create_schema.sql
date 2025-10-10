/* ======================================================================
   File    : 01_create_schema.sql
   Purpose : Creates logical schemas for the Renewable-Energy data
   Author  : Elene Kikalishvili
   Date    : 2025-05-02
   Depends : — (runs first)
   ====================================================================== */

CREATE SCHEMA IF NOT EXISTS renewables_project;

COMMENT ON SCHEMA renewables_project IS
  'Star-schema tables (dimensions, facts, look-ups) for Exploring Renewables';
