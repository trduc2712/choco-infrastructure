# 8. Serve Media Straight From B2

Date: 2026-11-01

## Status

Accepted

## Context

Choco's users can be anywhere, while its files sit in a B2 region outside Asia
([ADR 4](0004-use-backblaze-b2-for-object-storage.md)). Every download
straight from B2 counts against the account's daily limits of 1 GB and 2,500
Class B transactions, shared by every environment, past which downloads are
blocked until midnight GMT. A content delivery network
in front of the files would cache them close to users and keep those
downloads free, but it means a domain whose DNS it manages, another provider
and more setup. The MVP should stay simple.

## Considered Options

- Serve media straight from B2, with no content delivery network.
- Put Cloudflare's free plan in front of the bucket that holds media.

## Decision

Choco serves media straight from B2 for now, with no content delivery network.

- Media addresses point to the media bucket's public B2 address.
- Only the API builds media addresses
  ([ADR 10](0010-serve-media-from-a-public-bucket-behind-api-built-urls.md)),
  so adding a content delivery network later changes only the base address
  the API uses.
- No trigger is set yet for adding one. Images that stop loading once a daily
  limit is reached are accepted until then.

A content delivery network now would add a provider, DNS for a domain and
setup that the MVP does not need.

## Consequences

Easier:

- There is no other provider, account or DNS to set up for media.
- Adding a content delivery network later is a change to one setting, with no
  data to migrate.

Harder:

- Images load slowly for users far from B2's region.
- Every view of an image counts against B2's daily limits, so all
  environments together can show about 2,500 images a day. Past that, images
  stop loading everywhere until midnight GMT.
- B2 emails only at 75% and 100% of a limit; anything earlier means watching
  the Caps & Alerts page by hand.
- With no trigger set, the move to a content delivery network has to be
  noticed and decided by hand.
