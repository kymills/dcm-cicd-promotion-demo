-- Access control for the orders pipeline, managed declaratively by DCM.
--
-- DCM manages here:
--   * account roles (DEFINE ROLE) and database roles (DEFINE DATABASE ROLE)
--   * object privilege grants, role-to-role grants (the hierarchy below)
--   * role-to-user grants (GRANT ROLE ... TO USER) - supported, but users must
--     already exist; DCM cannot create users. Shown commented out at the bottom.
--
-- Stays outside DCM: creating users, assigning network/auth policies to users
-- or the account, and attaching masking / row access policies.
--
-- DCM only revokes what it deployed, so grants made by hand elsewhere are left alone.
--
-- Hierarchy (per environment):
--
--   SYSADMIN
--     └── ORDERS_PIPELINE_<env>_ADMIN
--           └── ORDERS_PIPELINE_<env>_ENGINEER   (+ <env>_WRITE)
--                 └── ORDERS_PIPELINE_<env>_ANALYST  (+ <env>_READ, WAREHOUSE_USER)

-- ---------------------------------------------------------------------------
-- Access roles: privileges on objects
-- ---------------------------------------------------------------------------

DEFINE DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ
COMMENT = 'Read-only access to the orders pipeline - {{env_name}}';

DEFINE DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_WRITE
COMMENT = 'Write access to raw orders - {{env_name}}';

DEFINE ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER
COMMENT = 'Warehouse access for the orders pipeline demo - {{env_name}}';

-- Warehouse access (must go to an account role, not a database role)
GRANT USAGE ON WAREHOUSE ORDERS_PIPELINE_{{env_name}}_WH TO ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER;

-- Read-only object access
GRANT USAGE ON DATABASE DCM_PROMO_DEMO TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_RAW TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_ANALYTICS TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_SERVE TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;

GRANT SELECT ON TABLE DCM_PROMO_DEMO.{{env_name}}_RAW.ORDERS TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT SELECT ON TABLE DCM_PROMO_DEMO.{{env_name}}_ANALYTICS.ORDERS_DAILY TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;
GRANT SELECT ON VIEW DCM_PROMO_DEMO.{{env_name}}_SERVE.ORDERS_SUMMARY TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ;

-- Write access to the raw layer
GRANT USAGE ON DATABASE DCM_PROMO_DEMO TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_WRITE;
GRANT USAGE ON SCHEMA DCM_PROMO_DEMO.{{env_name}}_RAW TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_WRITE;
GRANT INSERT, UPDATE, DELETE ON TABLE DCM_PROMO_DEMO.{{env_name}}_RAW.ORDERS TO DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_WRITE;

-- ---------------------------------------------------------------------------
-- Functional roles: what people are given
-- ---------------------------------------------------------------------------

DEFINE ROLE ORDERS_PIPELINE_{{env_name}}_ANALYST
COMMENT = 'Query the orders pipeline - {{env_name}}';

DEFINE ROLE ORDERS_PIPELINE_{{env_name}}_ENGINEER
COMMENT = 'Load and maintain orders data - {{env_name}}';

DEFINE ROLE ORDERS_PIPELINE_{{env_name}}_ADMIN
COMMENT = 'Owns day-to-day administration of the orders pipeline - {{env_name}}';

-- Access roles -> functional roles
GRANT DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_READ TO ROLE ORDERS_PIPELINE_{{env_name}}_ANALYST;
GRANT ROLE ORDERS_PIPELINE_{{env_name}}_WAREHOUSE_USER TO ROLE ORDERS_PIPELINE_{{env_name}}_ANALYST;
GRANT DATABASE ROLE DCM_PROMO_DEMO.{{env_name}}_WRITE TO ROLE ORDERS_PIPELINE_{{env_name}}_ENGINEER;

-- Functional role hierarchy, rolled up to SYSADMIN
GRANT ROLE ORDERS_PIPELINE_{{env_name}}_ANALYST TO ROLE ORDERS_PIPELINE_{{env_name}}_ENGINEER;
GRANT ROLE ORDERS_PIPELINE_{{env_name}}_ENGINEER TO ROLE ORDERS_PIPELINE_{{env_name}}_ADMIN;
GRANT ROLE ORDERS_PIPELINE_{{env_name}}_ADMIN TO ROLE SYSADMIN;

-- ---------------------------------------------------------------------------
-- Role -> user (example only; users must already exist outside DCM)
-- ---------------------------------------------------------------------------
-- GRANT ROLE ORDERS_PIPELINE_{{env_name}}_ANALYST TO USER <analyst_user>;
-- GRANT ROLE ORDERS_PIPELINE_{{env_name}}_ENGINEER TO USER <pipeline_service_user>;
