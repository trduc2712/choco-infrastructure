resource "neon_project" "db" {
  name                      = "choco-${var.environment}"
  org_id                    = var.neon_org_id
  region_id                 = var.database_region
  pg_version                = 17
  history_retention_seconds = var.database_history_retention_seconds

  branch {
    name          = "main"
    database_name = "choco"
    role_name     = "choco"
  }
}
