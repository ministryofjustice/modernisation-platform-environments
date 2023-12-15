resource "aws_ssm_document" "windows_domain_join" {
  name            = "windows-domain-join"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/windows-domain-join.yaml")

  tags = merge(
    local.tags,
    {
      Name = "windows-domain-join"
    },
  )
}

resource "aws_ssm_document" "cloud_watch_agent" {
  name            = "windows-cloudwatch-agent-config"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/windows-cloudwatch-agent-config.yaml")

  tags = merge(
    local.tags,
    {
      Name = "windows-cloudwatch-agent-config"
    },
  )
}

resource "aws_ssm_document" "ami_build_command" {
  name            = "ami-build-command"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/ami-build-command.yaml")

  tags = merge(
    local.tags,
    {
      Name = "ami-build-command"
    },
  )
}

resource "aws_ssm_document" "ami_build_automation" {
  name            = "ami-build-automation"
  document_type   = "Automation"
  document_format = "YAML"
  content         = file("./ssm-documents/ami-build-automation.yaml")

  tags = merge(
    local.tags,
    {
      Name = "ami-build-automation"
    },
  )
}

data "aws_elb_service_account" "default" {}
