# 4. Use Backblaze B2 for Object Storage

Date: 2026-11-01

## Status

Accepted

## Context

Choco stores files such as post images in object storage, used through the S3
API ([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)). The storage
has to be free and must never be able to bill for usage beyond its free tier.
It should be close to Singapore, where the API and the database run
([ADR 2](0002-host-the-api-on-render.md),
[ADR 3](0003-use-neon-for-postgresql.md)), cheap to download from, and
managed as code with the rest of the infrastructure.

## Considered Options

- Backblaze B2.
- Cloudflare R2.
- Amazon S3.
- MinIO hosted on a rented virtual machine.

## Decision

Choco uses Backblaze B2 for object storage.

- The account has no payment method, and none is ever added. Without one, B2
  keeps every cap at its free limit, so usage beyond it is blocked and cannot
  be billed.
- Choco uses B2 only through its S3 API.

Checked on 2026-11-03 in the account's Caps & Alerts page: without a payment
method, the daily caps are fixed at 10 GB of storage, 1 GB of downloads,
2,500 Class B transactions (such as downloads and metadata reads) and 2,500
Class C transactions, and they cannot be changed until a credit card is
added. [Caps](https://www.backblaze.com/docs/cloud-storage-data-caps-and-alerts)
reset at midnight GMT, with email alerts at 75% and 100%. B2 has
[no region in Asia](https://www.backblaze.com/docs/cloud-storage-data-regions).

B2 is chosen because, with no payment method, its usage cannot go past the
free limits, so it cannot turn into a bill. Cloudflare R2 needs a payment
method on file, and usage beyond its free tier is charged to it. Amazon S3
and a rented virtual machine running MinIO both cost money, which
[ADR 1](0001-run-on-free-tiers-behind-open-standards.md) rules out.

## Consequences

Easier:

- Object storage costs nothing and cannot be billed, with nothing to set up.
- Only the S3 API is used, so another S3-compatible provider can replace B2
  without changes to the application.

Harder:

- The nearest region is outside Asia, so uploads from users in Vietnam and
  the API's reads of uploaded files cross continents.
- Every environment shares 1 GB of downloads and 2,500 Class B transactions a
  day. Each image read straight from B2 and each object the API checks or
  reads counts against them.
- Once a day's cap is reached, the capped operations stop working until
  midnight GMT. What exactly fails has to be checked before relying on it.
- Raising any limit means adding a payment method, which this decision rules
  out.
