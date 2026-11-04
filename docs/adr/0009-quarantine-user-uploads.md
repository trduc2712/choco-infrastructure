# 9. Quarantine User Uploads

Date: 2026-11-01

## Status

Accepted

## Context

Users attach images to posts. Every uploaded file is untrusted: a file named
`photo.jpg` can be HTML or SVG with a script in it, an image header can be put
in front of something else, a small file can decode to billions of pixels, and
photos carry metadata such as the GPS position they were taken at.

Scaling without a rewrite is Choco's overriding goal
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)), and Choco is built
to learn from. The API runs on a small free instance that spins down when idle
([ADR 2](0002-host-the-api-on-render.md)), so it should not carry file
traffic. Even on a larger host, file traffic through the API ties up a
connection for the length of each upload and crosses the network twice. Clients are installed on users' devices, so the way they upload has
to stay the same as the platform grows. In B2, access is set per bucket, not
per file ([ADR 4](0004-use-backblaze-b2-for-object-storage.md)).

## Considered Options

- Upload straight to the bucket that media is served from.
- Upload through the API, which checks and stores each file within the
  request.
- Use a managed image service, such as Cloudinary or Cloudflare Images.
- Upload to a separate quarantine bucket, and publish only files that a
  background job has checked and encoded again.

## Decision

Choco uses a quarantine bucket for user uploads.

- Each environment has two buckets: an uploads bucket, which is private and
  holds files as clients upload them, and a media bucket, which holds only
  files Choco created from checked uploads.
- Clients upload straight to the uploads bucket with a short-lived presigned
  URL from the API. No file passes through the API.
- Nothing is ever served from the uploads bucket. Only the API's background
  jobs read from it ([ADR 7](0007-run-background-jobs-from-a-postgresql-queue.md)).
- A job decodes each image within size and pixel limits, encodes it again,
  writes the result to the media bucket and deletes the original. What is
  published is never the uploaded file, only pixels Choco encoded itself, so
  metadata and anything hidden in the file are dropped.

Uploading straight to the media bucket would serve files to anyone before
they were checked. Uploading through the API is the simplest
option and enough for the first users, but it makes the free instance a
bottleneck, and moving away from it later changes how every client uploads. A
managed image service would do the work for Choco, but its free tiers are
limited, it ties the platform to one vendor's API, and it teaches nothing
about how the work is done.

## Consequences

Easier:

- Nothing unchecked is ever published.
- Upload traffic and storage scale with B2, not with the API.
- The way clients upload does not change as the platform grows.
- Only the S3 API is used, so another S3-compatible provider can replace B2.

Harder:

- More parts: presigned URLs, CORS rules on the uploads bucket, two buckets
  per environment, a background job and a processing status for each file.
- An image is not visible until its job has run, which can take up to a
  minute when the API is spun down.
- Image processing runs on the API's instance and competes with requests for
  memory and CPU.
- The API reads each upload from a B2 region outside Asia, and those reads
  count against B2's free download allowance.
