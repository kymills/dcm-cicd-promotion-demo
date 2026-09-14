# DCM CI/CD Promotion Demo

A small, fully generic DCM (Database Change Management) project demonstrating how
Snowflake infrastructure gets promoted across environments (DEV -> QA -> PROD)
using Git branches and CI/CD, instead of ad hoc manual changes.

## What's here

- `manifest.yml` -- one project, three targets (DEV/QA/PROD), each pointing at an
  isolated, environment-suffixed set of schemas/objects in the same demo account.
- `sources/definitions/` -- a tiny "orders" pipeline (raw table -> dynamic table
  -> consumption view) plus a minimal read-only access role and a warehouse-access
  role, scoped only to this project's own objects.
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

## Commands used locally

```bash
snow dcm raw-analyze DATABASE.SCHEMA.PROJECT -c <connection> --target DEV
snow dcm plan DATABASE.SCHEMA.PROJECT -c <connection> --target DEV --save-output
snow dcm deploy DATABASE.SCHEMA.PROJECT -c <connection> --target DEV --alias "my-change"
snow dcm list-deployments DATABASE.SCHEMA.PROJECT -c <connection>
```
