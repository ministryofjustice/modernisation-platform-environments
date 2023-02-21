resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "InstallAndManageCloudWatchAgent"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./templates/install-and-manage-cwagent.yaml")

  tags = merge(
    local.tags,
    {
      Name = "install-and-manage-cloud-watch-agent"
    },
  )
}
resource "aws_cloudwatch_log_group" "groups" {
  for_each          = local.application_data.cw_log_groups
  name              = each.key
  retention_in_days = each.value.retention_days

  tags = merge(
    local.tags,
    {
      Name = each.key
    },
  )
}
resource "aws_ssm_parameter" "cw_agent_config" {
  description = "cloud watch agent config"
  name        = "cloud-watch-config"
  type        = "String"
  value       = file("./templates/cw_agent_config.json")

  tags = merge(local.tags,
    { Name = "cw-config" }
  )
}

resource "aws_ssm_association" "update_ssm_agent" {
  name             = "AWS-UpdateSSMAgent"
  association_name = "update-ssm-agent"
  parameters = {
    allowDowngrade = "false"
  }
  targets {
    # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
    key    = "tag:name"
    values = [lower(format("ec2-%s-%s-*", local.application_name, local.environment))]
  }
  apply_only_at_cron_interval = false
  schedule_expression         = "cron(30 7 ? * MON *)"
}
