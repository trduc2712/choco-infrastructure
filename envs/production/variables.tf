variable "render_api_key" {
  type      = string
  sensitive = true
}

variable "render_owner_id" {
  type = string
}

variable "clerk_authority" {
  type = string
}

variable "clerk_publishable_key" {
  type = string
}

variable "clerk_webhook_signing_secret" {
  type      = string
  sensitive = true
}

variable "clerk_secret_key" {
  type      = string
  sensitive = true
}

variable "neon_api_key" {
  type      = string
  sensitive = true
}

variable "neon_org_id" {
  type = string
}

variable "backblaze_application_key_id" {
  type      = string
  sensitive = true
}

variable "backblaze_application_key" {
  type      = string
  sensitive = true
}

variable "clerk_authorized_parties" {
  type = list(string)
}
