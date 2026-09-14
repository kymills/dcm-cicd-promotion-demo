-- Minimal access-control layer, scoped ONLY to this project's own objects.
-- Deliberately does NOT grant any role to a USER (unlike the Permifrost demo,
-- DCM has no notion of declarative user->role membership at all, so there is
-- no way for this project to touch account-level role assignments).

DEFINE DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ
COMMENT = 'Read-only access to the orders pipeline - {{env_name}}';

DEFINE ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER
COMMENT = 'Warehouse access for the orders pipeline demo - {{env_name}}';

-- Warehouse access (must go to an account role, not a database role)
GRANT USAGE ON WAREHOUSE ORDERS_PIPELINE_{{env_name}}_WH TO ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER;
GRANT ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER TO ROLE SYSADMIN;

-- Read-only object access
GRANT USAGE ON DATABASE DCM_PROMO_DEMO TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_RAW TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_ANALYTICS TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_SERVE TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;

GRANT SELECT ON TABLE DCM_PROMO_DEMO.{{env_name}}_RAW.ORDERS TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT SELECT ON TABLE DCM_PROMO_DEMO.{{env_name}}_ANALYTICS.ORDERS_DAILY TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT SELECT ON VIEW DCM_PROMO_DEMO.{{env_name}}_SERVE.ORDERS_SUMMARY TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;

GRANT DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ TO ROLE SYSADMIN;
