module "monitoring-sns-topic" {
  source      = "./modiles/sns_topic"
  application = "nomis-monitoring"
  env         = local.environment
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
  policy_arn = module.monitoring-sns-topic.sns_topic_policy
  role       = aws_iam_role.palertmanager-sns-role.name

}