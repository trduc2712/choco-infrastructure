# 12. Serve Media From a Private Bucket Through API-Signed URLs

Date: 2026-11-08

## Status

Accepted

## Context

[ADR 10](0010-serve-media-from-a-public-bucket-behind-api-built-urls.md)
chose a public media bucket with addresses that cannot be guessed. When the
media bucket was first applied on staging, on 2026-11-08, B2 refused to create
a public bucket on an account with no payment history (`no_payment_history`).
Choco's account has no card and never gets one
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md),
[ADR 4](0004-use-backblaze-b2-for-object-storage.md)), so no bucket of
Choco's can be public. This ADR replaces ADR 10.

Media is still served straight from B2, with no content delivery network
([ADR 8](0008-serve-media-straight-from-b2.md)). Its rule that media
addresses point to the media bucket's public address no longer holds; the
rest of it does. Files never pass through the API
([ADR 9](0009-quarantine-user-uploads.md)), and clients installed on users'
devices must keep working when the way media is served changes.

## Considered Options

- Make one payment so that B2 allows public buckets, and keep ADR 10.
- A private media bucket, with the API signing a short-lived download address
  for each file.
- A private media bucket, with a Cloudflare Worker checking a signed, expiring
  address in front of it.
- A private media bucket, with the API reading each file from B2 and sending
  it to the client.

## Decision

Choco serves media from a private bucket through download addresses the API
signs.

- Both buckets of an environment are private. Only the API's key can read the
  media bucket.
- The database stores keys, never addresses. Only the API turns a key into an
  address, and every response that refers to media carries the full address.
- Clients treat media addresses as expiring: they never keep one for later,
  and they ask the API again when one stops working.
- The API signs addresses for fixed time windows, so the same file gets the
  same address for the whole window and browsers can cache it. The length of
  the window is set in choco-api.

A payment breaks the rule that Choco never pays for anything but its domain.
A Worker needs Cloudflare in front of media, and so a domain, which Choco does
not have yet. Sending files through the API puts every image download on the
API's small free instance, which ADR 9 keeps file traffic away from.

## Consequences

Easier:

- No one can read a file without an address the API signed, so limits on who
  can see a post later only need the API to stop signing for that viewer.
- The data and installed clients stay the same, since ADR 10 already kept
  addresses out of the database and treated them as expiring.
- Moving to a Worker in front of the bucket later still changes only how the
  API builds addresses.

Harder:

- An address changes with every time window, so a browser downloads a file
  again in each new window.
- An address that leaks can be used by anyone until its window ends.
- Every response that refers to media costs the API one signature per file,
  computed locally without a network call.
- Clients must handle an address that has expired and fetch a new one.
- B2's daily download limits from ADR 8 still apply to every view.
