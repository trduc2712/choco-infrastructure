output "api_url" {
  value = render_web_service.api.url
}

output "uploads_bucket_name" {
  value = b2_bucket.uploads.bucket_name
}

output "web_url" {
  value = local.web_origin
}
