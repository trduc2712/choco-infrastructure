# 5. Manage Infrastructure With Terraform and HCP Terraform

Date: 2026-11-01

## Status

Accepted

## Context

Choco's infrastructure spans several providers
([ADR 2](0002-host-the-api-on-render.md),
[ADR 3](0003-use-neon-for-postgresql.md),
[ADR 4](0004-use-backblaze-b2-for-object-storage.md)). It should be described
as code, reviewed in pull requests and recreated the same way for every
environment, instead of being set up by hand in each provider's dashboard.
Whatever runs it and stores its state has to cost nothing
([ADR 1](0001-run-on-free-tiers-behind-open-standards.md)).

## Considered Options

- Terraform, with its state and runs in HCP Terraform.
- Terraform or OpenTofu, with its state in an S3-compatible bucket and runs
  on a developer's machine or in CI.
- Pulumi.

## Decision

Choco uses Terraform, with its state and runs in HCP Terraform.

- All infrastructure that a provider can manage through Terraform is
  described in this repository. One shared configuration is used by every
  environment.
- Each environment has its own HCP Terraform workspace, which plans on every
  change to its environment or to the shared configuration.
- Plans are applied by hand after review.
- Provider credentials and other secrets are sensitive workspace variables,
  never committed.
- The organization stays on the free plan; pay-as-you-go is never activated.
- Steps that no provider can do through Terraform are written down in
  [Bootstrap](../bootstrap.md).

Checked on 2026-11-01, the
[HCP Terraform free plan](https://developer.hashicorp.com/terraform/cloud-docs/overview)
needs no payment method and allows 500 managed resources and one run at a
time. Billing starts only when an organization activates
[pay-as-you-go](https://developer.hashicorp.com/terraform/cloud-docs/overview/activate-paygo),
which needs a payment method. What happens to a free organization above 500
resources is not documented.

Terraform is the most common infrastructure-as-code tool, and it already runs
Choco's infrastructure with HCP Terraform, which is free without a card and
runs plans in the cloud on every change. State in a bucket would mean running
plans and applies by hand or building that in CI. Pulumi would mean rewriting
the infrastructure in a programming language, with Choco's providers reached
only through a bridge to their Terraform providers.

## Consequences

Easier:

- Every change to the infrastructure is reviewed in a pull request.
- A new environment is created from the same configuration as the others.
- State is stored remotely and locked during runs, at no cost.
- OpenTofu runs the same configuration, so the command-line tool can be
  replaced without rewriting it.

Harder:

- Secrets end up in the Terraform state, readable by anyone with access to
  the workspace.
- One run at a time: a run waiting for confirmation blocks newer runs until
  it is applied or discarded.
- Behaviour above 500 managed resources on the free plan is unknown.
- HCP Terraform belongs to one vendor, which can change its free plan.
- Some setup still happens by hand, outside Terraform.
