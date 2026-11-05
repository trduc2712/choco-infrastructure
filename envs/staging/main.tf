module "choco" {
  source = "../../modules/choco"

  environment = "staging"
  namespace   = "trduc2712"

  api_plan                  = "free"
  api_auto_deploy_trigger   = "checksPass"
  api_documentation_enabled = true

  clerk_authority              = var.clerk_authority
  clerk_publishable_key        = var.clerk_publishable_key
  clerk_webhook_signing_secret = var.clerk_webhook_signing_secret
  clerk_secret_key             = var.clerk_secret_key
  clerk_authorized_parties     = var.clerk_authorized_parties
  bootstrap_admin_identity_ids = var.bootstrap_admin_identity_ids
  neon_org_id                  = var.neon_org_id
}
