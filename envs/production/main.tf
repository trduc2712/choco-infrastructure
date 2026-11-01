module "choco" {
  source = "../../modules/choco"

  environment = "production"
  namespace   = "trduc2712"

  api_plan                  = "starter"
  api_auto_deploy_trigger   = "off"
  api_documentation_enabled = false

  clerk_authority              = var.clerk_authority
  clerk_publishable_key        = var.clerk_publishable_key
  clerk_webhook_signing_secret = var.clerk_webhook_signing_secret
  clerk_secret_key             = var.clerk_secret_key
  clerk_authorized_parties     = var.clerk_authorized_parties
  neon_org_id                  = var.neon_org_id
}
