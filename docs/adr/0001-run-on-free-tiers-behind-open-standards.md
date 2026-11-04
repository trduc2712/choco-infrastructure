# 1. Run on Free Tiers Behind Open Standards

Date: 2026-11-01

## Status

Accepted

## Context

Choco is an API-first social network built to learn from, to show in a
portfolio, and to be used by real people. There is no budget for it at this
stage.

Scaling without a rewrite is the overriding goal. If growth goes far beyond
what is expected, Choco will need bigger, paid infrastructure, and moving
to it should mean swapping the services underneath the application, not
rewriting the application.

## Considered Options

- Use a cloud provider's paid managed services, such as AWS.
- Rent virtual machines and host every part of the platform on them.
- Use the free tiers of managed services, each through an open standard.

## Decision

Choco uses the free tiers of managed services, and uses each of them only
through an open standard.

- A service is chosen only if its free tier covers the first users.
- Choco depends on a service only through a standard that other providers
  implement too: Docker images to run the API, PostgreSQL for the database,
  the S3 API for object storage, OIDC and JWT for identity.
- Features that only one provider has stay out of the application, so a
  service can be replaced by another implementation of its standard, such as
  Backblaze B2 by Amazon S3.
- A domain is the one thing paid for. A service that could bill for usage
  beyond its free tier is used only if that usage can be blocked instead.

AWS's managed services cost money from the first month. Renting virtual
machines to host everything costs money too, before Choco has any users to
justify it.

## Consequences

Easier:

- Running Choco costs nothing but a domain, and cannot run up a bill by
  mistake.
- A provider can be replaced by another implementation of the same standard
  without changing the application or its clients.
- Each choice of provider is small and reversible, and gets its own ADR.

Harder:

- Free-tier limits shape the design: instances that spin down when idle,
  small database storage, no paid add-ons.
- Several providers mean several accounts, consoles and credentials to look
  after.
- Convenient features that go beyond a standard have to be left out.
- Free tiers change without notice, so their limits have to be checked again
  from time to time.
- When a free-tier limit is reached, the service stops until the limit
  resets, instead of growing.
