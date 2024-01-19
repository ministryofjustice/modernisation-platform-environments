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

resource "aws_ssm_document" "leave_windows_domain" {
  name            = "leave-windows-domain"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/leave-windows-domain.yaml")

  tags = merge(
    local.tags,
    {
      Name = "leave-windows-domain"
    },
  )
}

resource "aws_ssm_document" "remove_local_users_windows" {
  name            = "remove-local-users-windows"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/remove-local-users-windows.yaml")

  tags = merge(
    local.tags,
    {
      Name = "remove-local-users-windows"
    },
  )
}

resource "aws_ssm_document" "network-testing-tools" {
  name            = "network-testing-tools"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("./ssm-documents/network-testing-tools.yaml")

  tags = merge(
    local.tags,
    {
      Name = "network-testing-tools"
    },
  )
}
