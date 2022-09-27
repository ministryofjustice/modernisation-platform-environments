resource "aws_ssm_parameter" "subscriptions" {
  name  = "/monitoring/subscriptions"
  type  = "SecureString"
  value = jsonencode({ "emails" = [] })
  overwrite = true
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

module "monitoring-sns-topic" {
  source             = "./modules/sns_topic"
  application        = "nomis-monitoring"
  env                = local.environment
  topic_display_name = "Nomis monitoring ${local.environment} SNS topic"
  kms_master_key_arn = aws_kms_key.sns.arn
  kms_master_key_id  = aws_kms_key.sns.key_id
  ssm_parameter      = aws_ssm_parameter.subscriptions.value

  depends_on = [
    aws_ssm_parameter.subscriptions
  ]

}


resource "aws_iam_role" "alertmanager-sns-role" {
  name               = "AlertmanagerSNSTopicRole"
  assume_role_policy = data.aws_iam_policy_document.cloud-platform-monitoring-assume-role.json
  tags = merge(
    local.tags,
    {
      Name = "alertmanager-sns-distro-role"
    },
  )
}

resource "aws_iam_role_policy_attachment" "alertmanager_sns_topic_distro_policy_attach" {
  policy_arn = module.monitoring-sns-topic.sns_topic_policy.arn
  role       = aws_iam_role.alertmanager-sns-role.name

}
