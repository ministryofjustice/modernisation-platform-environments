# Redshift IAM role configuration for scheduled node pausing
resource "aws_iam_role" "wepi_iam_role_redshift_scheduler" {
  name               = "wepi-iam-role-${local.environment}-redshift-scheduler"
  assume_role_policy = file("${path.module}/json/wepi_iam_role_redshift_scheduler.json")
}

resource "aws_iam_policy" "wepi_iam_policy_redshift_scheduler" {
  name = "wepi-iam-policy-${local.environment}-redshift-scheduler"
  policy = templatefile("${path.module}/json/wepi_iam_policy_redshift_scheduler.json",
    {
      redshift_cluster = aws_redshift_cluster.wepi_redshift_cluster.arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "wepi_iam_attach_redshift_scheduler" {
  policy_arn = aws_iam_policy.wepi_iam_policy_redshift_scheduler.arn
  role       = aws_iam_role.wepi_iam_role_redshift_scheduler.name
}

# Redshift default IAM role configuration
resource "aws_iam_role" "wepi_iam_role_redshift_default" {
  name               = "wepi-iam-role-${local.environment}-redshift-default"
  assume_role_policy = file("${path.module}/json/wepi_iam_role_redshift_default.json")
}

resource "aws_iam_policy" "wepi_iam_policy_redshift_default" {
  name = "wepi-iam-policy-${local.environment}-redshift-default"
  policy = templatefile("${path.module}/json/wepi_iam_policy_redshift_default.json",
    {
      bucket_arn = aws_s3_bucket.wepi_redshift_logging_bucket.arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "wepi_iam_attach_redshift_default" {
  policy_arn = aws_iam_policy.wepi_iam_policy_redshift_default.arn
  role       = aws_iam_role.wepi_iam_role_redshift_default.name
}

# Glue IAM role
resource "aws_iam_role" "wepi_iam_role_glue" {
  name               = "wepi-iam-role-${local.environment}-glue"
  assume_role_policy = file("${path.module}/json/wepi_iam_role_glue.json")
}

resource "aws_iam_role_policy_attachment" "wepi_iam_attach_glue" {
  for_each   = data.aws_iam_policy.wepi_iam_glue_policy_list
  policy_arn = each.value.arn
  role       = aws_iam_role.wepi_iam_role_glue.name
}