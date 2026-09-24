## Auto Mode component logs — S3 delivery destination (#8430 task 3).
##
## A second set of destinations + deliveries alongside the CloudWatch ones in
## eks-cluster.tf. It REUSES the same four delivery sources (they are what trigger
## the serialised cluster updates) — this file adds no sources, so it does not
## touch that serialisation.
##
## Logs land in the shared bucket (fluent-bit-s3.tf). destination_resource_arn is
## the bucket ARN only (the S3 type is inferred from it); the per-type prefix is
## set via s3_delivery_configuration.suffix_path on the delivery below.

## One S3 destination per log type, all pointing at the shared bucket.
## output_format is intentionally omitted (defaults for S3; setting it can cause
## perpetual plan drift).
resource "aws_cloudwatch_log_delivery_destination" "auto_mode_s3" {
  for_each = local.auto_mode_log_types

  name = "${local.cluster_name}-${each.value}-s3"

  delivery_destination_configuration {
    destination_resource_arn = aws_s3_bucket.log_archive.arn
  }

  tags = local.tags
}

resource "aws_cloudwatch_log_delivery" "auto_mode_s3" {
  for_each = local.auto_mode_log_types

  delivery_source_name     = local.auto_mode_source_names[each.key]
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.auto_mode_s3[each.key].arn

  ## AWS prepends its own AWSLogs/<account>/... prefix; suffix_path is only our
  ## custom part. This gives an auto-mode/<type>/ segment within the AWS layout.
  ## TODO: confirm the object layout once applied — AWS-managed prefixes sit in
  ## front of this, so the final key is AWSLogs/<account>/.../auto-mode/<type>/.
  s3_delivery_configuration {
    suffix_path = "auto-mode/${each.value}"
  }

  tags = local.tags

  ## CreateDelivery needs the destination bucket policy in place first.
  depends_on = [aws_s3_bucket_policy.log_archive]
}
