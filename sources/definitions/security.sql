-- Network and authentication controls for each environment.
--
-- IMPORTANT: defining these policies does NOT enforce them. Assignment happens
-- outside DCM (ALTER USER / ALTER ACCOUNT / ALTER SECURITY INTEGRATION) - see
-- README "Access control & security". Nothing in this project assigns them.
--
-- allowed_cidrs defaults to documentation-reserved ranges (RFC 5737), so they
-- can never be mistaken for a real allow-list.

-- Network rule: schema-level. TYPE and MODE are immutable after first deploy.
DEFINE NETWORK RULE DCM_PROMO_DEMO.{{env_name}}_SECURITY.ALLOWED_INGRESS
    TYPE = IPV4
    MODE = INGRESS
    VALUE_LIST = ({% for cidr in allowed_cidrs %}'{{ cidr }}'{% if not loop.last %}, {% endif %}{% endfor %})
    COMMENT = 'Allowed inbound CIDR ranges - {{env_name}}';

-- Network policy: account-level, so the name carries the environment.
DEFINE NETWORK POLICY ORDERS_PIPELINE_{{env_name}}_NETWORK_POLICY
    ALLOWED_NETWORK_RULE_LIST = ('DCM_PROMO_DEMO.{{env_name}}_SECURITY.ALLOWED_INGRESS')
    COMMENT = 'Ingress allow-list for orders pipeline users - {{env_name}}';

-- Humans: password or SSO, MFA enrollment required.
-- SNOWFLAKE_UI must be allowed so users can enroll in MFA.
DEFINE AUTHENTICATION POLICY DCM_PROMO_DEMO.{{env_name}}_SECURITY.HUMAN_AUTH_POLICY
    AUTHENTICATION_METHODS = ('PASSWORD', 'SAML')
    MFA_ENROLLMENT = 'REQUIRED'
    CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS', 'SNOWFLAKE_CLI')
    COMMENT = 'People: SSO or password with MFA - {{env_name}}';

-- Service accounts (CI/CD, pipelines): key pair only, programmatic clients only.
DEFINE AUTHENTICATION POLICY DCM_PROMO_DEMO.{{env_name}}_SECURITY.SERVICE_AUTH_POLICY
    AUTHENTICATION_METHODS = ('KEYPAIR')
    -- MFA_ENROLLMENT defaults to REQUIRED, which demands SNOWFLAKE_UI; key pair
    -- users never enroll in MFA, so it must be explicitly OPTIONAL here.
    MFA_ENROLLMENT = 'OPTIONAL'
    CLIENT_TYPES = ('DRIVERS', 'SNOWFLAKE_CLI')
    COMMENT = 'Service users: key pair only, no UI - {{env_name}}';
