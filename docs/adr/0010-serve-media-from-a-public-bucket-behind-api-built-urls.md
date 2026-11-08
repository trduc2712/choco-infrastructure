# 10. Serve Media From a Public Bucket Behind API-Built URLs

Date: 2026-11-01

## Status

Superseded by [12](0012-serve-media-from-a-private-bucket-through-api-signed-urls.md)

## Context

Every post is public at first, but limits on who can see a post, such as
private accounts or blocked users, will come later. Images are loaded by
browsers and apps from a plain address, without the API's access token, so
whatever serves them cannot tell who is looking. Media is served straight
from B2 for now ([ADR 8](0008-serve-media-straight-from-b2.md)), and a cache
may be put in front of it later; any check on who may see a file is only safe
if it runs before such a cache.
Clients are installed on users' devices, so a change in how media addresses
work must not break the versions already installed.

## Considered Options

- A public media bucket, with addresses that cannot be guessed.
- A private media bucket, with the API signing a short-lived download address
  for every view.
- A private media bucket, with a Cloudflare Worker checking a signed,
  expiring address before the cache.

## Decision

Choco serves media from a public bucket, and only the API builds media
addresses.

- Every file's key holds a random identifier, so no address can be guessed.
- The database stores keys, never addresses.
- Only the API turns a key into an address, and every response that refers to
  media carries the full address. Clients never build one themselves.
- Clients treat media addresses as expiring: they never keep one for later,
  and they ask the API again when one stops working.

These rules let Choco move to the third option when posts stop being all
public: put Cloudflare in front of media, make the bucket private, add the
Worker, and change how the API builds addresses, with no change to the data
or to installed clients.

Signing every view in the API checks access, but every address is then
different, so neither browsers nor a cache can reuse a file already
downloaded, and every view goes through the API first. A Worker needs
Cloudflare in front of media, which Choco does not use yet, and it is code to
write and run. While every post is public, neither check protects anything.

## Consequences

Easier:

- Media is served straight from storage, with no code of Choco's in the path,
  and browsers can cache each file.
- Moving to checked access later needs no data migration and no client
  update.

Harder:

- Anyone who has a media address can open it for as long as the file exists,
  even after being blocked.
- Clients must handle an address that stops working, even though public
  addresses never do.
- Every response that refers to media has to be built by the API, which
  cannot hand out keys for clients to use directly.
