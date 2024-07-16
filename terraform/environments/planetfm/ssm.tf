locals {
  # this local is used in locals.tf
  ssm_doc_cloudwatch_log_groups = {
    for key, value in local.ssm_docs :
    "/aws/ssm/${try(value.name, key)}" => {
      retention_in_days = 30
    }
  }
  ssm_docs = {
    ami-build-automation = {
      document_type = "Automation"
      content       = file("./ssm-documents/ami-build-automation.yaml")
    }
    ami-build-command = {
      content = file("./ssm-documents/ami-build-command.yaml")
    }
    disable-azure-services = {
      content = file("./ssm-documents/disable-azure-services.yaml")
    }
    network-testing-tools = {
      content = file("./ssm-documents/network-testing-tools.yaml")
    }
    remove-local-users-windows = {
      content = file("./ssm-documents/remove-local-users-windows.yaml")
    }
    windows-cloudwatch-agent-config = {
      content = file("./ssm-documents/windows-cloudwatch-agent-config.yaml")
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
