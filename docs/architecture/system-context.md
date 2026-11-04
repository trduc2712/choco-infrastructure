# System Context

C4 level 1: Choco as one box, the people who use it, and the software systems it depends on.

```mermaid
flowchart TB
    user["<b>User</b><br/>[Person]<br/>Someone with a Choco account"]
    client["<b>Client application</b><br/>[Software System, external]<br/>Any app that calls the Choco API"]
    choco["<b>Choco</b><br/>[Software System]<br/>API-first social network"]
    clerk["<b>Clerk</b><br/>[Software System, external]<br/>Sign-up, sign-in and sessions"]

    user -- "Uses" --> client
    client -- "Signs the user in" --> clerk
    client -- "Calls with the user's token<br/>[HTTPS, JSON]" --> choco
    choco -- "Validates tokens, reads users<br/>[HTTPS]" --> clerk
    clerk -- "Sends user events<br/>[Webhooks]" --> choco

    classDef person fill:#08427b,stroke:#052e56,color:#fff
    classDef system fill:#1168bd,stroke:#0b4884,color:#fff
    classDef external fill:#8a8a8a,stroke:#6b6b6b,color:#fff
    class user person
    class choco system
    class client,clerk external
```

Dark blue is a person, blue is Choco, grey is a system outside Choco.

| Element | Type | Responsibility |
| --- | --- | --- |
| User | Person | Has one account. There is only one kind of user. |
| Client application | Software system, external | Any app that calls the API, including a first-party web or mobile app. Choco is API-first, so every client is outside it. |
| Choco | Software system | Profiles, follows, posts, feed, likes, comments and notifications. |
| Clerk | Software system, external | Owns identity: sign-up, sign-in, sessions, avatars. Choco never sees a password. |

What Choco is made of is in [Containers](containers.md).
