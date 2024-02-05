locals {
  ssm_docs = {
    windows-domain-join = {
      content = file("./ssm-documents/windows-domain-join.yaml")
    }
    windows-cloudwatch-agent-config = {
      content = file("./ssm-documents/windows-cloudwatch-agent-config.yaml")
    }
    ami-build-command = {
      content = file("./ssm-documents/ami-build-command.yaml")
    }
    ami-build-automation = {
      document_type = "Automation"
      content       = file("./ssm-documents/ami-build-automation.yaml")
    }
    leave-windows-domain = {
      content = file("./ssm-documents/leave-windows-domain.yaml")
    }
    remove-local-users-windows = {
      content = file("./ssm-documents/remove-local-users-windows.yaml")
    }
    network-testing-tools = {
      content = file("./ssm-documents/network-testing-tools.yaml")
    }
    # windows-psreadline-fix = {
    #   content = file("./ssm-documents/windows-psreadline-fix.yaml")
    # }
  }
}

resource "aws_ssm_document" "ssm_documents" {
  for_each = local.ssm_docs

  name            = try(each.value.name, each.key)
  document_type   = try(each.value.document_type, "Command")
  document_format = try(each.value.format, "YAML")
  content         = try(each.value.content)

  tags = merge(
    local.tags,
    {
      Name = try(each.value.name, each.key)
    },
  )
}
