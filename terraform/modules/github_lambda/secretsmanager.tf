resource "aws_secretsmanager_secret" "github_app" {
  name                    = "${var.project_name}/github-app"
  description             = "Private credentials for the github app used by the workflow scheduler"
  recovery_window_in_days = 7
}
