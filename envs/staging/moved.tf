# Resources were created from the repository root before the shared module existed.
# These blocks can be removed once every state has been applied with them.

moved {
  from = b2_bucket.uploads
  to   = module.choco.b2_bucket.uploads
}

moved {
  from = b2_application_key.api
  to   = module.choco.b2_application_key.api
}

moved {
  from = render_web_service.api
  to   = module.choco.render_web_service.api
}

moved {
  from = render_env_group.api
  to   = module.choco.render_env_group.api
}

moved {
  from = render_env_group_link.api
  to   = module.choco.render_env_group_link.api
}
