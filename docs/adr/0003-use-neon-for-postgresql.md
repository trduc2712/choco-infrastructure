# 3. Use Neon for PostgreSQL

Date: 2026-11-01

## Status

Accepted

## Context

Choco keeps its data in PostgreSQL
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)). The database has
to be free, run in Singapore next to the API
([ADR 2](0002-host-the-api-on-render.md)), be managed as code with the rest of
the infrastructure, and be backed up without extra work.

## Considered Options

- Neon.
- AWS.
- PostgreSQL hosted on a rented virtual machine.

## Decision

Choco uses Neon for PostgreSQL.

- Each environment has its own Neon project, in the AWS Singapore region.
- The database is restored from Neon's history, kept for the longest window
  the free plan allows.
- The API connects to the database directly, not through Neon's connection
  pooler, because the API pools its own connections. It moves to the pooler
  when several instances together come close to the database's connection
  limit.

Checked on 2026-11-01, the [Neon free plan](https://neon.com/pricing) gives
each project 1 GB of storage, 100 compute hours and 5 GB of network transfer a
month, with 20 GB of storage across all free projects. It stops the compute
after 5 minutes without queries, and this cannot be turned off. Reaching any
of these limits suspends the database until the next month
([limits and quotas](https://neon.com/faqs/free-plan-limits-and-quotas)).
History for restores is kept for at most 6 hours and 1 GB of changes.

Neon runs PostgreSQL as a managed service on the cloud, for free, and it is
recommended by someone who already runs it. AWS and a rented virtual machine
both cost money, which
[ADR 1](0001-run-on-free-tiers-behind-open-standards.md) rules out.

## Consequences

Easier:

- There is no database server to install, patch or back up.
- The database costs nothing.
- Any moment of the last 6 hours can be restored.
- It is standard PostgreSQL, so the data can move to another provider with
  PostgreSQL's own dump and restore tools.

Harder:

- 1 GB of storage fills up as content grows, and files can never be stored in
  the database.
- Going over a monthly limit takes the database down until the month ends.
- After 5 idle minutes the first query waits for the compute to start, on top
  of the API waking up.
- A mistake older than 6 hours, or behind more than 1 GB of changes, cannot
  be undone from Neon's history.
- The Terraform provider for Neon is maintained by the community, not by Neon,
  and its upgrades can replace resources if applied without review.
