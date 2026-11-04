# 7. Run Background Jobs From a PostgreSQL Queue

Date: 2026-11-01

## Status

Accepted

## Context

Choco needs work done in the background from the start: processing uploaded
images and applying events that Clerk sends, and later building feeds and
sending notifications. Render's free tier has no background workers
([ADR 2](0002-host-the-api-on-render.md)), the database is PostgreSQL
([ADR 3](0003-use-neon-for-postgresql.md)), and nothing may cost money
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)).

## Considered Options

- A hosted message broker on a free plan, such as Redis or RabbitMQ.
- PostgreSQL as the queue, with jobs run inside the API's process.

## Decision

Choco runs background jobs from a queue in PostgreSQL, inside the API's
process.

- A job is a row in the database.
- A job is enqueued in the same transaction as the change that causes it, so
  a change is never saved without its job, nor a job without its change.
- Workers claim jobs with row locks that skip rows already locked, so several
  API instances never run the same job.
- Every job can run more than once with the same result, because a job that
  fails halfway is retried.

A broker would add another provider and a second place where state lives,
and a change in the database and the message for it in the broker could not
be committed together.

## Consequences

Easier:

- There is one system to run and back up, and jobs survive restarts and
  spin-downs.
- Jobs and the changes that cause them are committed together, with no relay
  in between.
- Moving jobs to a separate worker later means running the same image with
  another command.

Harder:

- While Render has the API spun down, jobs wait until the next request wakes
  it.
- Jobs compete with requests for the instance's CPU and memory and for
  database connections.
- Polling the queue keeps the database awake while the API is awake, which
  spends Neon's monthly compute hours.
- PostgreSQL is a poor queue at very high volume. A broker becomes worth it
  when the queue shows up in the database's load.
