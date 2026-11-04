# Authentication and User Sync

How a request is authenticated, and how users in the database are kept in sync with Clerk. Both flows run independently: a user's first request can reach the API before Clerk's webhook does.

## Authenticated Request

```mermaid
sequenceDiagram
    participant Client
    participant Clerk
    participant API
    participant Database

    Client->>Clerk: Sign in
    Clerk-->>Client: Session JWT
    Client->>API: GET /api/me, Authorization: Bearer JWT
    API->>API: Validate signature (Clerk's cached signing keys), issuer, expiry
    API->>API: Check azp is an authorized party
    alt Token invalid
        API-->>Client: 401
    end
    API->>API: Apply the per-user rate limit
    API->>Database: Find user by identity_id (sub claim)
    alt User not found
        API->>Clerk: Backend API: retrieve user data
        alt Clerk has no such user
            API-->>Client: 401 User.Deleted
        end
        API->>Database: Create user, skipped if the webhook created it meanwhile
    end
    alt User is soft-deleted
        API-->>Client: 401 User.Deleted
    end
    API-->>Client: 200
```

## Clerk Webhook

```mermaid
sequenceDiagram
    participant Clerk
    participant API
    participant Database

    Clerk->>API: POST /api/webhooks/clerk (signed with Svix)
    API->>API: Verify the Svix signature
    alt Signature invalid
        API-->>Clerk: 401
    end
    alt Event is user.created
        API->>Database: Create user, unless it already exists
        API-->>Clerk: 200
    else Any other event
        API-->>Clerk: 200, ignored
    end
```

## Rules

- The API never calls Clerk to check a token. It validates the token against Clerk's signing keys, which it fetches from Clerk and caches.
- Tokens must carry an `azp` claim naming one of the configured frontend origins; the audience is not checked.
- A request looks its user up by `identity_id` at most once. If the user is missing, the API reads it from Clerk's Backend API and creates it, so clients never wait for the webhook.
- Creating a user checks `identity_id` again and does nothing if the user exists. While a request is calling Clerk's Backend API, the webhook can create the same user, and this check keeps the request from failing; the request then reads the user the webhook created.
- The webhook endpoint is anonymous; the Svix signature is its only check.

## Known Gaps

- `user.updated` and `user.deleted` are ignored, so changes and deletions in Clerk never reach the database.
- A request and the webhook creating the same user at the same moment both pass the existence check; the unique index on `identity_id` rejects one of them with a 500.
- Tokens without `azp`, such as those of non-browser clients, are rejected.

How a token maps to a user, and these gaps in more detail, are in choco-api's [User Identity](https://github.com/trduc2712/choco-api/blob/main/docs/user-identity.md). Choosing Clerk is choco-api [ADR 2](https://github.com/trduc2712/choco-api/blob/main/docs/adr/0002-use-clerk-as-identity-provider.md).
