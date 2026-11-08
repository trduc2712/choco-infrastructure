# Object Storage

How Choco's buckets and the objects in them are named. Why there are two buckets is in [ADR 9](adr/0009-quarantine-user-uploads.md). [ADR 10](adr/0010-serve-media-from-a-public-bucket-behind-api-built-urls.md) chose a public media bucket, but B2 refuses to create a public bucket on an account with no payment history, so the media bucket is private and the API signs short-lived download addresses for it, the second option ADR 10 considered. ADR 10 is to be replaced by an ADR that records this.

## Buckets

| Bucket | Access | Staging | Production |
| --- | --- | --- | --- |
| Uploads | Private | `trduc2712-choco-staging-uploads` | `trduc2712-choco-production-uploads` |
| Media | Private | `trduc2712-choco-staging-media` | `trduc2712-choco-production-media` |

Names follow `<namespace>-choco-<environment>-<role>`:

- B2 bucket names are global across all accounts, so `trduc2712` keeps them from clashing with anyone else's.
- Only lowercase letters, digits and hyphens, 6 to 63 characters, which is valid for both B2's native API and its S3-compatible API ([Backblaze](https://www.backblaze.com/docs/cloud-storage-buckets)).
- No periods: they break HTTPS with virtual-hosted-style addresses ([Backblaze](https://www.backblaze.com/docs/cloud-storage-buckets), [AWS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)).
- No reserved prefix (`b2-`, `xn--`, `sthree-`, `amzn-s3-demo-`) and no personal data.
- A bucket cannot be renamed; a new name means a new bucket.

## Lifecycle and Access

| Bucket | Lifecycle | CORS |
| --- | --- | --- |
| Uploads | Every file is hidden a day after upload and deleted a day after hiding; unfinished large files are cancelled after a day. Every upload is gone within 72 hours. | `PUT` through the S3 API from the environment's frontend origins only, with the `content-type` header, cached for an hour |
| Media | Hidden files are deleted seven days after hiding, so a file deleted by mistake can be restored within that week; unfinished large files are cancelled after a day. Files the API has not deleted never expire. | None: images are loaded with plain `GET` requests, which need no CORS rule |

- The lifecycle rules are a backstop. The API decides when an upload has expired and rejects pending media older than 24 hours, well before the bucket hides it.
- The frontend origins are the same list the API accepts tokens from: the Vercel project's address and `clerk_authorized_parties`.
- The API has one key per environment, covering both buckets with `listAllBucketNames`, `readFiles`, `writeFiles` and `deleteFiles`. It cannot list the files in either bucket. The master key is only used by Terraform.
- `DeleteObject` through the S3 API without a version id only hides a file: B2 adds a delete marker and keeps the file, which still counts towards storage, until the bucket's lifecycle rule deletes it: a day later in the uploads bucket, seven days later in the media bucket. Checked on staging on 2026-11-08.

## Identifiers

Every uploaded file has two identifiers:

| Identifier | Used in | Form |
| --- | --- | --- |
| Media id | The database and the API | UUIDv7, ordered by time so database indexes stay compact |
| Storage token | Object keys, and so media addresses | 128 random bits from a cryptographically secure generator, in lowercase base32 (26 characters) |

The storage token is what makes a media address impossible to guess. A UUID is not used for it: [RFC 9562](https://www.rfc-editor.org/rfc/rfc9562) says UUIDs should not be assumed hard to guess, and a UUIDv7 starts with its creation time.

## Keys

| Bucket | Key | Example |
| --- | --- | --- |
| Uploads | `<storage token>` | `k3v7q2m9x4b8n1c6d5f0g2h7j9` |
| Media | `<kind>/<storage token>/<variant>.webp` | `posts/k3v7q2m9x4b8n1c6d5f0g2h7j9/w1080.webp` |

- `<kind>` groups files by feature, such as `posts`. A new kind of file gets a new prefix, never a new bucket.
- `<variant>` names one processed size of the image, such as `w1080`.
- Keys use only lowercase letters, digits, `/`, `.` and `-`, the characters that need no special handling ([AWS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html)).
- Keys never contain a user id, a user's file name or other personal data ([Backblaze](https://www.backblaze.com/docs/cloud-storage-files), [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)).
- A key is never written twice. Writing an existing name in B2 keeps the old file as a version that is still billed.
- The database stores keys, never addresses; the API builds addresses from them.
