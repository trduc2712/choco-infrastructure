data "b2_account_info" "current" {}

resource "b2_bucket" "uploads" {
  bucket_name = "${var.namespace}-choco-${var.environment}-uploads"
  bucket_type = "allPrivate"

  lifecycle_rules {
    file_name_prefix                                       = ""
    days_from_starting_to_canceling_unfinished_large_files = 1
  }
}

resource "b2_application_key" "api" {
  key_name     = "${var.namespace}-choco-${var.environment}-api"
  bucket_ids   = [b2_bucket.uploads.bucket_id]
  capabilities = ["listBuckets", "listFiles", "readFiles", "writeFiles", "deleteFiles"]
}
