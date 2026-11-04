# 6. Run Separate Staging and Production Environments

Date: 2026-11-01

## Status

Accepted

## Context

Changes to Choco need somewhere to be tried before real users see them, and
real users' data must never mix with test data. Every environment has to run
on free tiers ([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)), and
Render's free hours are shared by every service in the workspace
([ADR 2](0002-host-the-api-on-render.md)).

## Considered Options

- One environment, used by real users and for trying changes.
- Two separate environments: staging and production.

## Decision

Choco has two separate environments: staging, where changes are tried, and
production, which real users use.

- Each environment has its own copy of every resource: API service, database,
  buckets, identity instance and infrastructure workspace
  ([ADR 5](0005-manage-infrastructure-with-terraform-and-hcp-terraform.md)).
  Nothing is shared between them, neither data nor credentials.
- Both environments run on free tiers, production included.
- Staging uses Clerk's development instance. Production uses Clerk's
  production instance on Choco's own domain.
- Staging deploys every change to the API that passes its checks. Production
  deploys only by hand.

With one environment, every change would be tried where real users are, on
their data.

## Consequences

Easier:

- Changes are tried without affecting real users.
- Test data and test accounts never reach production.
- A leaked staging credential gives no access to production.

Harder:

- Staging and production share Render's 750 free hours a month. If both stay
  awake for most of the month, the hours run out and both stop until the next
  month.
- Every resource and every manual setup step exists twice.
- Production needs a domain, the one paid item.
- Staging and production can drift apart when one is changed by hand.
