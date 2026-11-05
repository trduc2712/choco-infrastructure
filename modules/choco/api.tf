resource "render_web_service" "api" {
  name              = "choco-api-${var.environment}"
  plan              = var.api_plan
  region            = var.api_region
  health_check_path = var.api_health_check_path
  runtime_source = {
    docker = {
      repo_url            = var.api_repo_url
      branch              = var.api_branch
      auto_deploy         = var.api_auto_deploy_trigger != "off"
      auto_deploy_trigger = var.api_auto_deploy_trigger
    }
  }

  # render-oss/render 1.9.1 fails every update of a free-tier service
  # (render-oss/terraform-provider-render#80), so the health check path is only set on
  # create. Change it in the Render dashboard until the provider is fixed.
  lifecycle {
    ignore_changes = [health_check_path]
  }
}

resource "render_env_group" "api" {
  name = "choco-api-${var.environment}"

  env_vars = merge(
    {
      ASPNETCORE_ENVIRONMENT              = { value = local.aspnetcore_environment }
      ASPNETCORE_HTTP_PORTS               = { value = "10000" }
      ASPNETCORE_FORWARDEDHEADERS_ENABLED = { value = "true" }
      ApiDocumentation__Enabled           = { value = tostring(var.api_documentation_enabled) }
      Clerk__Authority                    = { value = var.clerk_authority }
      Clerk__PublishableKey               = { value = var.clerk_publishable_key }
      Clerk__SecretKey                    = { value = var.clerk_secret_key }
      Clerk__WebhookSigningSecret         = { value = var.clerk_webhook_signing_secret }
      Cors__AllowedOrigins__0             = { value = local.web_origin }
      Database__ConnectionString          = { value = local.database_connection_string }
      Storage__ServiceUrl                 = { value = local.storage_service_url }
      Storage__Region                     = { value = local.storage_region }
      Storage__BucketName                 = { value = b2_bucket.uploads.bucket_name }
      Storage__AccessKeyId                = { value = b2_application_key.api.application_key_id }
      Storage__SecretAccessKey            = { value = b2_application_key.api.application_key }
    },
    local.clerk_authorized_parties_env_vars,
    local.bootstrap_admin_env_vars,
  )
}

resource "render_env_group_link" "api" {
  env_group_id = render_env_group.api.id
  service_ids  = [render_web_service.api.id]
}
