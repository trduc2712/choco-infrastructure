variable "environment" {
  type = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be either \"staging\" or \"production\"."
  }
}

variable "namespace" {
  description = "Globally unique prefix for resources that share a global namespace, such as B2 buckets."
  type        = string
}

variable "api_plan" {
  type    = string
  default = "free"
}

variable "api_region" {
  type    = string
  default = "singapore"
}

variable "api_repo_url" {
  type    = string
  default = "https://github.com/trduc2712/choco-api"
}

variable "api_branch" {
  type    = string
  default = "main"
}

variable "api_auto_deploy_trigger" {
  description = "One of \"commit\", \"checksPass\" or \"off\"."
  type        = string
  default     = "checksPass"

  validation {
    condition     = contains(["commit", "checksPass", "off"], var.api_auto_deploy_trigger)
    error_message = "api_auto_deploy_trigger must be \"commit\", \"checksPass\" or \"off\"."
  }
}

variable "api_health_check_path" {
  type    = string
  default = "/health"
}

variable "api_documentation_enabled" {
  type    = bool
  default = false
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

variable "clerk_authorized_parties" {
  description = "Origins of frontends other than the web frontend allowed to call the API (checked against the azp claim)."
  type        = list(string)
  default     = []
}

variable "bootstrap_admin_identity_ids" {
  description = "Clerk user ids the API gives the system admin role at startup and when the user is created. It never removes the role."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.bootstrap_admin_identity_ids : startswith(id, "user_")])
    error_message = "bootstrap_admin_identity_ids must contain only Clerk user ids (user_...)."
  }
}

variable "web_repo" {
  type    = string
  default = "trduc2712/choco-web"
}

variable "web_production_branch" {
  type    = string
  default = "main"
}

variable "web_node_version" {
  type    = string
  default = "22.x"
}

variable "neon_org_id" {
  type = string
}

variable "database_region" {
  type    = string
  default = "aws-ap-southeast-1" # Singapore, next to the Render service
}

variable "database_history_retention_seconds" {
  description = "Point-in-time restore window. The Neon Free plan allows at most 21600 (6 hours)."
  type        = number
  default     = 21600
}
