data "b2_account_info" "current" {}

resource "b2_bucket" "uploads" {
  bucket_name = "${var.namespace}-choco-${var.environment}-uploads"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix                                       = ""
    days_from_uploading_to_hiding                          = 1
    days_from_hiding_to_deleting                           = 1
    days_from_starting_to_canceling_unfinished_large_files = 1
  }

  cors_rules {
    cors_rule_name     = "browser-uploads"
    allowed_origins    = local.frontend_origins
    allowed_operations = ["s3_put"]
    allowed_headers    = ["content-type"]
    max_age_seconds    = 3600
  }
}

resource "b2_bucket" "media" {
  bucket_name = "${var.namespace}-choco-${var.environment}-media"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix                                       = ""
    days_from_starting_to_canceling_unfinished_large_files = 1
  }
}

resource "b2_application_key" "api" {
  key_name     = "${var.namespace}-choco-${var.environment}-api"
  bucket_ids   = [b2_bucket.uploads.bucket_id, b2_bucket.media.bucket_id]
  capabilities = ["listAllBucketNames", "readFiles", "writeFiles", "deleteFiles"]
}
