# Bootstrap

Terraform creates the Neon project, the Render service and env group, the B2 buckets and the API's B2 key, and the Vercel project with its environment variables. Everything below is done by hand, once per environment (`<env>` is `staging` or `production`).

## Accounts and Keys

- **Render**: API key, workspace ID (`tea-…`), and a GitHub connection with access to `trduc2712/choco-api`.
- **Neon**: personal API key and organization ID (`org-…`).
- **Backblaze B2**: the Master Application Key; ordinary keys cannot create the key Terraform makes for the API. Every bucket is private: B2 refuses to create a public bucket on an account with no payment history, and Choco's account never gets a card.
- **Vercel**: an account token (Account Settings → Tokens) on the Hobby plan, and the Vercel GitHub App installed with access to `trduc2712/choco-web`.
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
| `vercel_api_token` | yes | Vercel account token |
| `clerk_authorized_parties` | | Optional HCL list, tick **HCL**, of origins other than the web frontend's, which Terraform adds itself. They are allowed as token parties and as origins that may upload to the uploads bucket; e.g. `[]` |
| `bootstrap_admin_identity_ids` | | Optional HCL list, tick **HCL**, of the environment's Clerk user ids (`user_…`) the API makes system admins; e.g. `["user_…"]`. The API only adds the role, so removing an id does not revoke it |

## First Apply

1. Apply. The service deploys before its env group is linked and fails; run **Deploy latest commit** afterwards.
2. Set Health Check Path to `/health` in the dashboard if the service already existed: the provider cannot update free-plan services ([render-oss/terraform-provider-render#80](https://github.com/render-oss/terraform-provider-render/issues/80)).
3. Add the Clerk webhook endpoint `https://choco-api-<env>.onrender.com/api/webhooks/clerk`, put its secret in `clerk_webhook_signing_secret`, then apply and deploy again.
4. In `trduc2712/choco-api`, create Environment `<env>` limited to branch `main`, with secret `DATABASE_CONNECTION_STRING` in Npgsql form (Neon → Connect, pooling off):

   ```
   Host=<host>;Database=choco;Username=choco;Password=<password>;SSL Mode=Require
   ```

5. Check that the Vercel project's production domain is `choco-web-<env>.vercel.app`, the `web_url` output. If the name was taken and Vercel gave another domain, the API rejects the frontend's tokens and requests.
6. Deploy the frontend: staging builds on every push to `main` of `trduc2712/choco-web`. Production builds only from its `production` branch, which `vercel.json` there must enable; create the branch and push to it to deploy.

## Day-to-Day

- Changes go through a PR, then **Confirm & Apply** after merge. Discard stale runs waiting for confirmation; they block newer ones.
- Changing a variable does not queue a run: use **New run**.
- After an env change, run **Deploy latest commit**. Render does not redeploy on its own, and **Restart** keeps the old env.
- Changing the buckets or capabilities of the API's B2 key replaces the key, so its secret changes and the old one stops working at once. Run **Deploy latest commit** right after the apply; until then the API cannot reach B2.
- After a change to the frontend's environment variables, redeploy it on Vercel. Vite builds them into the bundle, so a running deployment keeps the old values.
