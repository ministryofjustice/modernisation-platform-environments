#------------------------------------------------------------------------------
# Prometheus Cloud Platform User
# Used to monitor mod-platform resources from the Cloud Platform cluster
# See Cloud Platform namespace "dso-monitoring-prod"
#------------------------------------------------------------------------------

resource "aws_iam_user" "prometheus_cp_user" {
  name = "prometheus_cp_user"
}

resource "aws_iam_access_key" "prometheus_cp_user_key" {
  user = aws_iam_user.prometheus_cp_user.name
}

resource "aws_iam_user_policy" "policy" {
  name        = "EC2-Read-Only"
  user        = aws_iam_user.prometheus_cp_user.name
  # AmazonEC2ReadOnlyAccess Policy
  policy      = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
EOT
}

resource "github_actions_secret" "prometheus_key_id" {
  repository      = "dso-monitoring"
  secret_name     = "prometheus_key_id"
  plaintext_value = aws_iam_access_key.prometheus_cp_user_key.id
}

resource "github_actions_secret" "prometheus_secret_key" {
  repository      = "dso-monitoring"
  secret_name     = "prometheus_secret_key"
  plaintext_value = aws_iam_access_key.prometheus_cp_user_key.secret
}
