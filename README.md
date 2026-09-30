# DCM CI/CD Promotion Demo

A small, fully generic DCM (Database Change Management) project demonstrating how
Snowflake infrastructure gets promoted across environments (DEV -> QA -> PROD)
using Git branches and CI/CD, instead of ad hoc manual changes.

## What's here

- `manifest.yml` -- one project, three targets (DEV/QA/PROD), each pointing at an
  isolated, environment-suffixed set of schemas/objects in the same demo account.
- `sources/definitions/` -- a tiny "orders" pipeline (raw table -> dynamic table
  -> consumption view), a functional role hierarchy (`access.sql`), and network +
  authentication policies (`security.sql`).
- `.github/workflows/dcm-promote.yml` -- the CI/CD pipeline. Every PR runs
  `snow dcm plan` and posts the diff as a check. Every merge deploys. PROD is
  additionally gated behind a required-reviewer GitHub Environment.

## The promotion flow

```
feature/*  --PR + plan diff-->  develop  --auto-deploy-->  DEV
develop    --PR + plan diff-->  staging  --auto-deploy-->  QA
staging    --PR + plan diff-->  main     --approval + deploy--> PROD
```

Nothing reaches PROD without (1) a reviewed plan diff in a PR and (2) an explicit
human approval on the `PROD` GitHub Environment.

## Why this exists

This is the direct, native answer to "our production account became our dev
environment" -- every change to every environment goes through the same
Git-reviewed, plan-then-deploy path. There's no path for an ad hoc change to
land anywhere without going through source control first.

## Access control & security

The same Git-reviewed flow manages who can do what, not just the pipeline objects.

### Role hierarchy (per environment)

```
SYSADMIN
  +-- ORDERS_PIPELINE_<env>_ADMIN
        +-- ORDERS_PIPELINE_<env>_ENGINEER    + database role <env>_WRITE
              +-- ORDERS_PIPELINE_<env>_ANALYST   + database role <env>_READ
                                                  + ORDERS_PIPELINE_<env>_WAREHOUSE_USER
```

- **Access roles** (database roles `<env>_READ` / `<env>_WRITE`, plus the warehouse
  role) hold object privileges.
- **Functional roles** (`ANALYST`, `ENGINEER`, `ADMIN`) are what people are given.
- Role-to-user grants are supported (`GRANT ROLE ... TO USER`), shown as commented
  examples in `access.sql` because users must already exist.

### Network and authentication policies (`security.sql`)

| Object | Scope | Purpose |
|---|---|---|
| `DCM_PROMO_DEMO.<env>_SECURITY.ALLOWED_INGRESS` | network rule | per-env CIDR allow-list from `allowed_cidrs` in `manifest.yml` |
| `ORDERS_PIPELINE_<env>_NETWORK_POLICY` | network policy (account-level) | references the rule |
| `<env>_SECURITY.HUMAN_AUTH_POLICY` | auth policy | password/SSO, MFA enrollment required |
| `<env>_SECURITY.SERVICE_AUTH_POLICY` | auth policy | key pair only, programmatic clients only |

The CIDRs in `manifest.yml` are RFC 5737 documentation ranges. Replace them
before using this for real.

### What DCM manages vs. what it doesn't

| DCM manages | Stays outside DCM |
|---|---|
| Account roles, database roles, role hierarchy | Creating users |
| Object privilege grants, role-to-user grants | Assigning network/auth policies to users or the account |
| Network rules, network policies, auth policies | Attaching masking / row access policies |

DCM only revokes grants it deployed, so hand-made grants elsewhere are left alone.

### Defined is not enforced

Defining a policy does **not** activate it. Nothing in this project assigns one.
Assign manually, **one test user first**:

```sql
ALTER USER <test_user> SET NETWORK_POLICY = ORDERS_PIPELINE_DEV_NETWORK_POLICY;
ALTER USER <test_user> SET AUTHENTICATION POLICY DCM_PROMO_DEMO.DEV_SECURITY.HUMAN_AUTH_POLICY;
ALTER USER <ci_service_user> SET AUTHENTICATION POLICY DCM_PROMO_DEMO.DEV_SECURITY.SERVICE_AUTH_POLICY;
```

Never assign a network policy account-wide (`ALTER ACCOUNT SET NETWORK_POLICY`)
from this demo. If your own IP isn't in the allow-list, you lock everyone out.

## Commands used locally

```bash
snow dcm raw-analyze DATABASE.SCHEMA.PROJECT -c <connection> --target DEV
snow dcm plan DATABASE.SCHEMA.PROJECT -c <connection> --target DEV --save-output
snow dcm deploy DATABASE.SCHEMA.PROJECT -c <connection> --target DEV --alias "my-change"
snow dcm list-deployments DATABASE.SCHEMA.PROJECT -c <connection>
```
