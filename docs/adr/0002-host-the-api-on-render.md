# 2. Host the API on Render

Date: 2026-11-01

## Status

Accepted

## Context

The API is packaged as a Docker image ([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)).
It needs a host that runs that image for free, deploys it automatically when
the API's GitHub repository changes, runs close to Vietnam and next to the
database, and can be managed as code with the rest of the infrastructure.

## Considered Options

- Render.
- A virtual machine rented and run by Choco.
- AWS.

## Decision

Choco uses Render to host the API.

- The API runs as a Render web service built from its Docker image, on the
  free instance type.
- Render builds and deploys the API from GitHub on its own, with no pipeline
  of Choco's to maintain.
- The service runs in Render's Singapore region.

Checked on 2026-11-01, [Render's free tier](https://render.com/docs/free)
offers web services only, with no background workers. A free service spins
down after 15 minutes without traffic and takes up to a minute to wake, and
the workspace shares 750 instance hours a month across all its free services.

AWS and a rented virtual machine both cost money, which
[ADR 1](0001-run-on-free-tiers-behind-open-standards.md) rules out. A virtual
machine would also need a deploy pipeline built and maintained by hand.

## Consequences

Easier:

- Hosting costs nothing and needs no credit card, so it cannot run up a bill.
- A push to the API's repository deploys it, with nothing to build or run.
- The API runs in the same region as the database.

Harder:

- The first request after 15 idle minutes waits up to a minute for the API to
  wake.
- Every environment's free service draws on the same 750 hours a month, so
  two services running all month would run out before it ends.
- Work in the background has to run inside the API's own process, because
  free background workers do not exist.
- Files written to the instance's disk are lost on every deploy and restart.
- Render's Terraform provider cannot update free services
  ([render-oss/terraform-provider-render#80](https://github.com/render-oss/terraform-provider-render/issues/80)),
  so some settings are changed in the Render dashboard instead.
