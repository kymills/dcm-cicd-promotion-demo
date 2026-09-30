-- Per-environment warehouse and schemas.
-- {{env_name}} resolves to DEV / QA / PROD depending on --target, so the same
-- source file deploys three isolated, same-shaped environments in one database.

DEFINE WAREHOUSE ORDERS_PIPELINE_{{env_name}}_WH
WITH
    WAREHOUSE_SIZE = '{{wh_size}}'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Compute for the orders pipeline demo - {{env_name}}';

DEFINE SCHEMA DCM_PROMO_DEMO.{{env_name}}_RAW
COMMENT = 'Raw / source layer - {{env_name}}';

DEFINE SCHEMA DCM_PROMO_DEMO.{{env_name}}_ANALYTICS
COMMENT = 'Transformation layer (mirrors compiled dbt marts) - {{env_name}}';

DEFINE SCHEMA DCM_PROMO_DEMO.{{env_name}}_SERVE
COMMENT = 'Consumption layer - {{env_name}}';

DEFINE SCHEMA DCM_PROMO_DEMO.{{env_name}}_SECURITY
COMMENT = 'Schema-level security objects (network rules, authentication policies) - {{env_name}}';
