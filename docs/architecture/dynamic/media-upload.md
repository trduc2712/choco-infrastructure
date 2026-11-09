# Media Upload

How an image goes from a user's device to a post. Files never pass through the API: the client uploads to the uploads bucket, a background job checks and encodes each upload into the media bucket, and the client reads images from the media bucket. A post can only be created with images that are already ready, so no one ever sees a post whose images are still being processed.

## Upload

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Database
    participant UploadsBucket

    Client->>API: POST /api/v1/media { contentType, size }
    API->>API: Validate the token, apply the per-user rate limit
    API->>API: Check contentType is JPEG, PNG or WebP and size is at most 10 MB
    alt Type or size not allowed
        API-->>Client: 400
    end
    API->>Database: Begin a transaction, lock the user's row (SELECT ... FOR UPDATE)
    API->>Database: Count the user's media that is Pending or Processing, and created in the last 24 hours
    alt 4 in progress, or 40 in the last 24 hours
        API->>Database: Roll back
        API-->>Client: 429 Media.UploadLimitReached
    end
    API->>Database: Sum variant_bytes of all media, plus declared size of media created in the last 72 hours
    alt Sum plus size over the environment's budget
        API->>Database: Roll back
        API-->>Client: 503 Media.StorageFull
    end
    API->>Database: Create media: Pending, owner, declared size, new storage token, commit
    API->>API: Sign a PUT URL for the storage token, valid 10 minutes, with Content-Type and Content-Length signed
    API-->>Client: 201 { mediaId, uploadUrl }

    Client->>UploadsBucket: PUT uploadUrl, Content-Type, Content-Length
    UploadsBucket->>UploadsBucket: Check the signature, signed headers, expiry and CORS origin
    UploadsBucket-->>Client: 200

    Client->>API: POST /api/v1/media/{id}/complete
    API->>Database: Find media by id and owner
    alt Not found
        API-->>Client: 404
    else Already Processing or Ready
        API-->>Client: 202, nothing changes
    else Failed
        API-->>Client: 409
    end
    alt Created more than 1 hour ago
        API-->>Client: 410 Media.UploadExpired
    end
    API->>UploadsBucket: HEAD storage token
    alt Object missing
        API-->>Client: 409 Media.NotUploaded
    end
    alt Size over 10 MB, or Content-Type differs
        API->>Database: Mark media Failed, only while it is Pending
        API->>UploadsBucket: DELETE storage token
        API-->>Client: 422
    end
    API->>Database: Begin a transaction: UPDATE media SET Processing WHERE id AND Pending
    alt No row updated
        API->>Database: Roll back
        API-->>Client: 202, another request already completed it
    end
    API->>Database: Enqueue a processing job, commit
    API-->>Client: 202
```

## Processing

```mermaid
sequenceDiagram
    participant BackgroundJob
    participant Database
    participant UploadsBucket
    participant MediaBucket

    BackgroundJob->>Database: Claim the next due job (FOR UPDATE SKIP LOCKED): set a new lease_id, locked_until to now + 5 minutes, add 1 to attempts, commit
    Note over BackgroundJob,Database: Due: not completed, run_at has passed, and locked_until is empty or past. No transaction stays open while the job runs. Each instance runs one image job at a time.
    alt attempts over 3
        BackgroundJob->>Database: Mark media Failed, complete the job
    end
    BackgroundJob->>UploadsBucket: GET storage token
    alt Object missing
        BackgroundJob->>Database: Mark media Failed, complete the job
    end
    alt Content-Length over 10 MB, or the stream passes 10 MB
        BackgroundJob->>BackgroundJob: Stop reading
        BackgroundJob->>Database: Mark media Failed, complete the job
    end
    BackgroundJob->>BackgroundJob: Read the format and dimensions from the header, without decoding pixels
    alt Not JPEG, PNG or WebP, over 40 MP, or over 8192 px per side
        BackgroundJob->>Database: Mark media Failed, complete the job
    end
    BackgroundJob->>BackgroundJob: Decode the first frame only, apply the EXIF orientation, convert to sRGB
    BackgroundJob->>BackgroundJob: Encode WebP at about q80 in w320, w640 and w1080, never upscaled, with no metadata
    BackgroundJob->>MediaBucket: PUT posts/<storage token>/<variant>.webp for each variant
    BackgroundJob->>Database: Begin a transaction: UPDATE media SET Ready, variant_bytes WHERE id AND Processing AND the job's lease_id is this worker's
    alt No row updated
        BackgroundJob->>Database: Roll back
        Note over BackgroundJob: The lease was lost to another worker: stop without deleting anything
    end
    BackgroundJob->>Database: Complete the job, commit
    BackgroundJob->>UploadsBucket: DELETE storage token
    Note over BackgroundJob,MediaBucket: Every write to the media row or the job, Failed included, only applies while the job's lease_id is this worker's. If the process stops or a call to B2 or the database fails before the job is completed, the job is claimed again once locked_until has passed.
```

## Creating a Post

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Database

    loop Until Ready or Failed
        Client->>API: GET /api/v1/media/{id}
        API-->>Client: 200 { status }
    end

    Client->>API: POST /api/v1/posts { text, mediaIds }
    API->>API: Check at most 4 mediaIds, no duplicates
    API->>Database: Begin a transaction, insert the post
    API->>Database: UPDATE media SET post_id WHERE id IN mediaIds AND owner is the user AND Ready AND post_id IS NULL
    alt Fewer rows updated than mediaIds
        API->>Database: Roll back
        API-->>Client: 409
    end
    API->>Database: Commit
    API-->>Client: 201, Location: /api/v1/posts/{id}
```

## Reading

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Database
    participant MediaBucket

    Client->>API: GET /api/v1/posts/{id}
    API->>Database: Read the post and its media keys
    API->>API: Sign a GET URL for each variant, the same for the whole time window, expiring at the end of the next window
    API-->>Client: 200 { text, media: [{ variant, url }] }
    Client->>MediaBucket: GET url
    MediaBucket-->>Client: 200 image/webp
    alt Refused, for an expired URL or B2's daily download limit
        MediaBucket-->>Client: 403
        Client->>API: GET /api/v1/posts/{id} once more
        Client->>MediaBucket: GET the new url
        alt Refused again
            Client->>Client: Show a placeholder, do not ask again
        end
    end
```

## Cleanup

```mermaid
sequenceDiagram
    participant BackgroundJob
    participant Database
    participant UploadsBucket
    participant MediaBucket

    BackgroundJob->>Database: Claim the sweep job once its run_at has passed, with a lease as for any job
    BackgroundJob->>Database: Begin a transaction: DELETE up to 100 media WHERE post_id IS NULL AND Pending, Ready or Failed AND created over 24 hours ago (FOR UPDATE SKIP LOCKED), RETURNING storage tokens
    BackgroundJob->>Database: Enqueue a file deletion job for each storage token
    BackgroundJob->>Database: Complete the sweep job, enqueue the next one with run_at in 1 hour, or now if 100 were deleted, commit

    BackgroundJob->>Database: Claim a file deletion job
    BackgroundJob->>UploadsBucket: DELETE storage token
    BackgroundJob->>MediaBucket: DELETE posts/<storage token>/<variant>.webp for w320, w640 and w1080
    BackgroundJob->>Database: Complete the job
    Note over BackgroundJob,MediaBucket: A 404 from DELETE counts as deleted, so the job is the same whichever files an upload got to. Each DELETE only hides a file, and the bucket's lifecycle deletes it later.
```

## Rules

### Checks

- Every check that matters runs in the API or the job, never only in the client.
- The size the client declares is signed into the upload URL, checked again with `HEAD` at completion, and checked a third time by the job against the bytes it actually reads. The upload URL stays valid after completion, so the client can replace the file after `HEAD`; only the job's own check counts.
- The job reads the format and dimensions from the file's header before it decodes any pixel, and decodes only the first frame, so an animated or oversized image never reaches memory. A 40 MP frame is about 160 MB decoded, which is why each instance runs one image job at a time.
- Nothing is ever read from the uploads bucket except by the job. What lands in the media bucket is always pixels the job encoded itself, never the uploaded file.
- The job applies the EXIF orientation and converts to sRGB before it drops the metadata, so photos keep the way they look on the device that took them.

### Quotas

- Quotas are checked when an upload is requested, the only point before any byte reaches a bucket. They protect three hard limits: B2's 10 GB of storage and 2,500 Class B transactions a day for the whole account, and the API's 0.1 CPU and 512 MB, which every upload costs one processing job.
- A user can have at most 4 media Pending or Processing at a time, one post's worth, so no one can open many upload URLs at once.
- A user can request at most 40 uploads in 24 hours, counted from the media table. The sweep only deletes media older than 24 hours, so it never lowers the count.
- Each environment has a storage budget: 2 GB for staging and 7 GB for production, leaving 1 GB of the account for files that are hidden but not yet deleted. Used storage is the variant bytes of every media, which the job records when it marks media Ready, plus the declared size of every media created in the last 72 hours, whose original may still be in the uploads bucket. An upload that would pass the budget is refused for everyone with 503 `Media.StorageFull`. Without it, 100 users each within their own quota could still put 40 GB of originals into the uploads bucket in a day.
- The user's row is locked while counting, so two requests from the same user cannot both pass at 39. The storage budget takes no lock and can be passed slightly when many users upload at once; the 1 GB left over covers that.
- A user over their own quota gets 429 `Media.UploadLimitReached`, and a full environment gets 503 `Media.StorageFull`, so a client can tell the user which one it is.

### Expiry

- The API, not the bucket's lifecycle, decides when an upload has expired: media still Pending an hour after it was created is rejected. The upload URL is valid for 10 minutes, so an hour is enough to finish an upload, and leaves the job about 23 hours before the uploads lifecycle can hide the original.
- The lifecycle rules only remove what the API never cleaned up.

### Jobs

- Completing an upload moves media from Pending to Processing with a conditional `UPDATE` and enqueues the job in the same transaction. Two requests completing the same upload enqueue one job, and completing it again returns 202 without changing anything.
- Jobs are claimed with a lease: the claim sets a new `lease_id` and `locked_until` and commits at once, so no database connection is held while an image is downloaded, decoded and uploaded. A job whose process stopped, from a Render spin-down, a deploy or running out of memory, is claimed again when its lease ends.
- `lease_id` is a fencing token. A worker that outlived its lease finds its writes update no row, so it can never mark media Failed after another worker made it Ready.
- A job runs at most 3 times. After that its media is marked Failed.
- The original is deleted only after the media is Ready, so a retry can always read it. If the original is gone when a job runs, the media is marked Failed.
- A job that stops after marking media Ready but before deleting the original leaves the original behind. This is accepted: no one ever reads it, and the uploads lifecycle removes it within 72 hours of its upload, so it costs storage for at most three days.
- Jobs run inside the API's process ([ADR 7](../../adr/0007-run-background-jobs-from-a-postgresql-queue.md)), so while Render has the API spun down ([ADR 2](../../adr/0002-host-the-api-on-render.md)) they wait for the next request to wake it. This is accepted: the client's own polling after completing an upload is such a request, so an image is late by the time the API takes to start, up to about a minute.
- A retry writes the variants an earlier attempt already wrote. B2 hides the older version as soon as the new one is uploaded, and the media bucket's lifecycle deletes it seven days later ([Backblaze](https://www.backblaze.com/docs/cloud-storage-lifecycle-rules)), so a retry costs storage for a week, nothing more. Media is not visible until it is Ready, so no one sees a variant change.

### Cleanup

- Media not attached to a post 24 hours after it was created is deleted, whatever it reached: Pending, Ready or Failed. Media still Processing is left alone; its job ends in Ready or Failed, and the next sweep after that removes it.
- The media row is deleted, and a job to delete its files is enqueued, in one transaction. A crash between the two can therefore never leave files with no row pointing to them. This matters because the API's key cannot list either bucket, so a file the database has forgotten could never be found again.
- The file deletion job deletes every key an upload can have: the original and all three variants. A Failed upload may have written some variants before it failed, and this removes them too. A key that does not exist counts as deleted: the job treats a 404 from `DELETE` as success, so it never fails on a variant an upload never wrote, whatever B2 answers.
- A post created at the same moment as a sweep cannot keep deleted media: the sweep and the post's `UPDATE` lock the same rows, and whichever commits second finds the media gone or already attached. A post that loses gets 409.
- The sweep is a job like any other, so it runs only while the API is awake and never on two instances at once. The API enqueues it at startup unless one is already waiting, and a unique index on the waiting sweep job keeps two instances starting together from enqueuing two. It deletes at most 100 media per run and runs again at once while more are due.
- Deleted files stay hidden for seven days in the media bucket before the lifecycle removes them, so media deleted by mistake can still be restored within that week.

### Posts and Reading

- Media belongs to at most one post. The same picture uploaded twice gets two media ids.
- Attaching media to a post is one conditional `UPDATE` in the post's transaction, so a post never holds media that is not Ready, not the user's, or already used. Two posts using the same media at once both wait on the row lock, and the second updates no row and rolls back.
- A post has no processing status of its own: it is visible once created, because all its media is already Ready.
- A client has 24 hours from requesting an upload to create the post that uses it; after that the media is gone and the post gets 409.
- Retrying a failed or expired upload is up to the client: it starts again with `POST /api/v1/media`.
- The database stores keys, never addresses. Every response that refers to media carries addresses the API signed for the current time window. Each address expires at the end of the next window, so an address handed out at the last second of a window still works for a whole window.
- A client asks for new addresses once per refused image. A refusal that survives new addresses is B2's daily limit or a missing file, and asking again would only load the API.

## To Verify on Staging

- How long a job takes for a 40 MP image on Render's free instance. If it comes close to 5 minutes, jobs routinely run twice; the lease must then be longer, or renewed while the job runs.

## Known Gaps

- Whether B2 refuses a presigned `PUT` whose body length differs from the signed `Content-Length` is not checked. If it does not, one upload URL can store up to 5 GB, as many times as the client likes within 10 minutes. A single user could then fill the account's 10 GB, shared by every environment, and block every upload and every processing job until the uploads lifecycle has removed the files, up to 72 hours later.
- Quotas and the storage budget count the size the client declares. Until it is known that B2 enforces the signed `Content-Length`, a client that declares 1 KB and uploads more is not stopped by them.
- How much space the three variants of an image take has not been measured, so how many images fit in each budget is not known yet; about 250 KB per image is an estimate.
- A job whose process stopped waits up to 5 minutes for its lease to end, so its image is late by that much.
- An image that runs the instance out of memory takes the API down with it, up to 3 times before its media is Failed.

Why uploads are quarantined is [ADR 9](../../adr/0009-quarantine-user-uploads.md), the job queue is [ADR 7](../../adr/0007-run-background-jobs-from-a-postgresql-queue.md), and why media is served through signed addresses is [ADR 12](../../adr/0012-serve-media-from-a-private-bucket-through-api-signed-urls.md). Bucket names, keys and lifecycles are in [Object Storage](../../object-storage.md).
