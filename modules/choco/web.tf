resource "vercel_project" "web" {
  name         = "choco-web-${var.environment}"
  framework    = "vite"
  node_version = var.web_node_version

  git_repository = {
    type              = "github"
    repo              = var.web_repo
    production_branch = var.web_production_branch
  }

  preview_deployments_disabled = true

  vercel_authentication = {
    deployment_type = "standard_protection_new"
  }
}

resource "vercel_project_environment_variables" "web" {
  project_id = vercel_project.web.id

  variables = [
    {
      key       = "VITE_API_BASE_URL"
      value     = render_web_service.api.url
      target    = ["production"]
      sensitive = false
    },
    {
      key       = "VITE_CLERK_PUBLISHABLE_KEY"
      value     = var.clerk_publishable_key
      target    = ["production"]
      sensitive = false
    },
  ]
}
