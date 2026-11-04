# 11. Host the Web Frontend on Vercel

Date: 2026-11-04

## Status

Accepted

## Context

Choco's web frontend is a single-page application that its build turns into
static files. It needs a host that serves those files for free
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)), builds and deploys
them when the frontend's GitHub repository changes, gives staging and
production separate copies
([ADR 6](0006-run-separate-staging-and-production-environments.md)), and can
be managed as code with the rest of the infrastructure
([ADR 5](0005-manage-infrastructure-with-terraform-and-hcp-terraform.md)).

The API accepts a user's token only when its `azp` claim names a known
frontend origin ([Authentication](../architecture/dynamic/authentication.md)),
and browsers can call it only from origins it allows. Each deployed frontend
therefore needs an address that is known before it is deployed and does not
change between deploys.

## Considered Options

- Vercel.
- Cloudflare Pages.
- Netlify.
- GitHub Pages.

## Decision

Choco uses Vercel's Hobby plan to host the web frontend.

- Each environment has its own Vercel project, built from the same
  repository. Staging deploys every push to the main branch. Production
  deploys only when its own branch is pushed to by hand.
- Preview deployments are turned off. Each would get a new address that the
  API does not know, so signing in from it would fail.
- The frontend is served from its project's Vercel address until Choco has a
  domain.
- The API keeps the origins it allows for browser calls separate from the
  origins it accepts in tokens, even though both name the frontend.
- The frontend's settings, such as the API's address, are built into its
  files, so a changed setting takes effect only after a new deploy.

Checked on 2026-11-04, [Vercel's Hobby plan](https://vercel.com/docs/plans/hobby)
is free and includes 100 GB of data transfer and 1,000,000 CDN requests a
month, and 100 deployments a day. It never bills: a feature that goes over its
limit stops until 30 days have passed.
[Vercel's fair use guidelines](https://vercel.com/docs/limits/fair-use-guidelines)
allow Hobby only for non-commercial personal use. Taking payments, showing
ads and being paid to build or host the site all count as commercial use;
asking for donations does not.

Cloudflare Pages and Netlify also serve static files for free, build from
GitHub and can be managed as code. They lost only because Vercel's free tier
already covers the first users and its Terraform provider manages everything
the frontend needs, so the choice between the three is close. GitHub Pages
needs a build pipeline in GitHub Actions that Choco would maintain, and serves
one site per repository, which makes separate staging and production copies
harder.

## Consequences

Easier:

- Hosting the frontend costs nothing and cannot run up a bill.
- A push to the frontend's repository deploys staging, with no pipeline to
  maintain.
- The frontend's projects and settings are managed as code with the rest of
  the infrastructure.
- The frontend is only static files, so moving it to another host means
  building it there and pointing its address at the new host.

Harder:

- Hobby allows only non-commercial use. Once Choco earns money, from ads or
  payments, the frontend has to move to another host, recorded in a new ADR.
- If a project's name is taken, Vercel gives it a different address, and the
  API rejects the frontend until its lists of origins are changed.
- With previews turned off, a change to the frontend is first seen on
  staging, not on an address of its own.
- When Choco gets a domain, the frontend's origin changes, and the API's
  token and browser origin lists, and the uploads bucket's, change with it.
- Vercel is one more account, token and console to look after.
