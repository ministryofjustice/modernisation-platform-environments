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

output "secret_key" {
  value     = aws_iam_access_key.prometheus_cp_user_key.secret
  sensitive = true
}

output "access_key" {
  value = aws_iam_access_key.prometheus_cp_user_key.id
}
