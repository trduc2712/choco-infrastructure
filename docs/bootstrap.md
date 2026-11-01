# Bootstrap

Terraform creates the Neon project, the Render service and env group, and the B2 bucket. Everything below is done by hand, once per environment (`<env>` is `staging` or `production`).

## Accounts and Keys

- **Render**: API key, workspace ID (`tea-…`), and a GitHub connection with access to `trduc2712/choco-api`.
- **Neon**: personal API key and organization ID (`org-…`).
- **Backblaze B2**: the Master Application Key; ordinary keys cannot create the key Terraform makes for the API.
- **Clerk**: no Terraform provider. Staging uses the Development instance, production the Production instance.
- **Terraform Cloud**: `terraform login`.

## Terraform Cloud Workspace

Run `terraform init` in `envs/<env>` to create the workspace, then set:

- Working Directory `envs/<env>` (the root loads `../../modules/choco`), and Manual apply.
- Version Control: `trduc2712/choco-infrastructure`, triggering only on `/envs/<env>/**/*` and `/modules/**/*`.
- Variables, all of category **Terraform variable**:

| Variable | Sensitive | Value |
| --- | --- | --- |
| `render_api_key` | yes | Render API key |
| `render_owner_id` | | Render workspace ID, `tea-…` |
| `backblaze_application_key_id` | yes | keyID of the B2 master key |
| `backblaze_application_key` | yes | applicationKey of the B2 master key |
| `neon_api_key` | yes | Neon personal API key |
| `neon_org_id` | | Neon organization ID, `org-…` |
| `clerk_authority` | | Clerk Frontend API URL |
| `clerk_publishable_key` | | `pk_test_…` (staging) or `pk_live_…` (production) |
| `clerk_secret_key` | yes | `sk_test_…` or `sk_live_…` |
| `clerk_webhook_signing_secret` | yes | `whsec_…` of the environment's webhook endpoint; a placeholder until the endpoint exists |
| `clerk_authorized_parties` | | HCL list, tick **HCL**, e.g. `["https://choco-api-staging.onrender.com"]` |

## First Apply

1. Apply. The service deploys before its env group is linked and fails; run **Deploy latest commit** afterwards.
2. Set Health Check Path to `/health` in the dashboard if the service already existed: the provider cannot update free-plan services ([render-oss/terraform-provider-render#80](https://github.com/render-oss/terraform-provider-render/issues/80)).
3. Add the Clerk webhook endpoint `https://choco-api-<env>.onrender.com/api/webhooks/clerk`, put its secret in `clerk_webhook_signing_secret`, then apply and deploy again.
4. In `trduc2712/choco-api`, create Environment `<env>` limited to branch `main`, with secret `DATABASE_CONNECTION_STRING` in Npgsql form (Neon → Connect, pooling off):

   ```
   Host=<host>;Database=choco;Username=choco;Password=<password>;SSL Mode=Require
   ```

## Day-to-Day

- Changes go through a PR, then **Confirm & Apply** after merge. Discard stale runs waiting for confirmation; they block newer ones.
- Changing a variable does not queue a run: use **New run**.
- After an env change, run **Deploy latest commit**. Render does not redeploy on its own, and **Restart** keeps the old env.
