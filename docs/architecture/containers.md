# Containers

C4 level 2: what runs and stores data inside Choco, and how the parts talk to each other and to the systems around them.

```mermaid
flowchart TB
    user["<b>User</b><br/>[Person]<br/>Someone with a Choco account"]
    client["<b>Client application</b><br/>[Software System, external]<br/>Any app that calls the Choco API"]
    clerk["<b>Clerk</b><br/>[Software System, external]<br/>Sign-up, sign-in and sessions"]

    subgraph choco["Choco [Software System]"]
        api["<b>API</b><br/>[Container: ASP.NET Core, Docker]<br/>Business logic, background jobs"]
        db[("<b>Database</b><br/>[Container: PostgreSQL]<br/>Data and job queue")]
        uploads[("<b>Uploads bucket</b><br/>[Container: S3 object storage, private]<br/>Unchecked uploads, expire after a day")]
        media[("<b>Media bucket</b><br/>[Container: S3 object storage, public]<br/>Images encoded from checked uploads")]
    end

    user -- "Uses" --> client
    client -- "Signs the user in" --> clerk
    client -- "Calls with the user's token<br/>[HTTPS, JSON]" --> api
    client -- "Uploads images<br/>[HTTPS, presigned URL]" --> uploads
    client -- "Reads images<br/>[HTTPS]" --> media
    clerk -- "Sends user events<br/>[Webhooks]" --> api
    api -- "Validates tokens, reads users<br/>[HTTPS]" --> clerk
    api -- "Reads and writes<br/>[SQL]" --> db
    api -- "Signs upload URLs, reads and deletes originals<br/>[S3 API]" --> uploads
    api -- "Writes encoded images<br/>[S3 API]" --> media

    classDef person fill:#08427b,stroke:#052e56,color:#fff
    classDef container fill:#438dd5,stroke:#2e6295,color:#fff
    classDef external fill:#8a8a8a,stroke:#6b6b6b,color:#fff
    class user person
    class api,db,uploads,media container
    class client,clerk external
    style choco fill:none,stroke:#0b4884,stroke-dasharray:6 4
```

Dark blue is a person, light blue is a container inside Choco, grey is a system outside Choco. Cylinders store data; the dashed border is Choco's boundary.

| Container | Technology | Responsibility | Decided in |
| --- | --- | --- | --- |
| API | ASP.NET Core in a Docker image | All business logic. Validates tokens, signs upload URLs, builds media addresses, and runs background jobs in the same process, such as processing uploaded images. Keeps no state of its own, so it can run as many instances as needed. | [ADR 2](../adr/0002-host-the-api-on-render.md), [ADR 7](../adr/0007-run-background-jobs-from-a-postgresql-queue.md) |
| Database | PostgreSQL | The source of truth, and the queue of background jobs. Stores object keys, never media addresses. | [ADR 3](../adr/0003-use-neon-for-postgresql.md), [ADR 7](../adr/0007-run-background-jobs-from-a-postgresql-queue.md) |
| Uploads bucket | S3-compatible object storage, private | Files as clients upload them, before they are checked. Only the API reads them. Each is removed within a few days. | [ADR 9](../adr/0009-quarantine-user-uploads.md) |
| Media bucket | S3-compatible object storage, public | Images the API encoded again from checked uploads. Readable by anyone with an address, and addresses come only from the API. Keys are never reused. | [ADR 9](../adr/0009-quarantine-user-uploads.md), [ADR 10](../adr/0010-serve-media-from-a-public-bucket-behind-api-built-urls.md) |

Files never pass through the API: clients upload to the uploads bucket and read from the media bucket directly. Bucket names, keys and lifetimes are in [Object Storage](../object-storage.md).

Where each container runs is decided in [ADR 2](../adr/0002-host-the-api-on-render.md) (Render), [ADR 3](../adr/0003-use-neon-for-postgresql.md) (Neon) and [ADR 4](../adr/0004-use-backblaze-b2-for-object-storage.md) (Backblaze B2).
