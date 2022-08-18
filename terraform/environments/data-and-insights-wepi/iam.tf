# Redshift IAM configuration for scheduled node pausing
resource "aws_iam_role" "wepi_iam_role_redshift_scheduler" {
  name               = "wepi-iam-role-${local.environment}-redshift-scheduler"
  assume_role_policy = file("${path.module}/json/wepi_iam_role_redshift_scheduler.json")
}

resource "aws_iam_policy" "wepi_iam_policy_redshift_scheduler" {
  name   = "wepi-iam-policy-${local.environment}-redshift-scheduler"
  policy = templatefile("${path.module}/json/wepi_iam_policy_redshift_scheduler.json",
    {
      redshift_cluster = aws_redshift_cluster.wepi_redshift_cluster.arn
    }
  )
}

resource "aws_iam_policy_attachment" "wepi_iam_attach_redshift_scheduler" {
  policy_arn = aws_iam_policy.wepi_iam_policy_redshift_scheduler.arn
  role       = aws_iam_role.wepi_iam_role_redshift_scheduler.name
}
