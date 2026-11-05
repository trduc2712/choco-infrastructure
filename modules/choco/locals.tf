locals {
  storage_service_url = data.b2_account_info.current.s3_api_url
  storage_region      = regex("s3\\.([^.]+)\\.", local.storage_service_url)[0]

  aspnetcore_environment = title(var.environment)

  web_origin = "https://${vercel_project.web.name}.vercel.app"

  clerk_authorized_parties_env_vars = {
    for index, party in distinct(concat([local.web_origin], var.clerk_authorized_parties)) :
    "Clerk__AuthorizedParties__${index}" => { value = party }
  }

  bootstrap_admin_env_vars = {
    for index, id in distinct(var.bootstrap_admin_identity_ids) :
    "Authorization__BootstrapAdminIdentityIds__${index}" => { value = id }
  }

  # Npgsql does not accept postgres:// URIs. The direct host is used instead of the
  # pooler because Npgsql pools connections itself.
  database_connection_string = join(";", [
    "Host=${neon_project.db.database_host}",
    "Database=${neon_project.db.database_name}",
    "Username=${neon_project.db.database_user}",
    "Password=${neon_project.db.database_password}",
    "SSL Mode=Require",
  ])
}
