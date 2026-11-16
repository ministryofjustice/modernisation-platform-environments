# ------------------------------------------------------------------------------
# S3 request metrics for the `incoming` bucket.
#
# Each ingress channel writes to a distinct key prefix in this bucket:
#   - SFTP/FTPS (custom IdP Lambda): "<username>/..." (TRANSFER_HOME_DIRECTORY_DETAILS)
#   - Web app (S3 Access Grants):    "group/<group-name>/..."
#   - API (cross-account presigned): "<client-key-prefix>/..."
#
# SFTP and FTPS share the same per-username prefix (a user can connect over
# either protocol to the same home directory), so they can't be split from
# each other by prefix
#
# These request metrics configurations give us:
#   - "EntireBucket": every request to the bucket (all channels combined)
#   - "web": requests scoped to the web app's "group/" prefix
#   - one filter per API client prefix: requests scoped to that client only
#
# Dashboard math: SFTP+FTPS combined = EntireBucket - web - sum(api clients).
# PutRequests counts PUT requests, not objects (each part of a multipart upload
# is a PUT), so the dashboard treats it as an approximation of objects placed.
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_metric" "incoming_all_requests" {
  bucket = module.s3_bucket["incoming"].s3_bucket_id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_metric" "incoming_web_requests" {
  bucket = module.s3_bucket["incoming"].s3_bucket_id
  name   = "web"

  filter {
    prefix = "group/"
  }
}

resource "aws_s3_bucket_metric" "incoming_api_client_requests" {
  for_each = local.api_client_prefixes

  bucket = module.s3_bucket["incoming"].s3_bucket_id
  name   = "api-${each.key}"

  filter {
    prefix = "${each.value}/"
  }
}
