locals {
  aliases                              = ["sherlock-landing"]
  application                          = "data-factory-corporate"
  component                            = "people"
  eventbridge_rule_name                = "eventbridge-malware-rule"
  enable_external_iam_role             = true
  enable_guardduty_slack_notifications = true
  cloudtrail_name                      = "corporate-cloudtrail"

  # Apply with false, populate the secret, then set true and apply again.
  # Switching back to false removes the role and provider, but keeps the secret.
  enable_airflow_iam_role = true

  # Use the same cluster identifier for the provider and role trust policy.
  airflow_oidc_cluster_identifier = local.enable_airflow_iam_role ? jsondecode(data.aws_secretsmanager_secret_version.airflow-authentication[0].secret_string)["oidc_cluster_identifier"] : ""
}

