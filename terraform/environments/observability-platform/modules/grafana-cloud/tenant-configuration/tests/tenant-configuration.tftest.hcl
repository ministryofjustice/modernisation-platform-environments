# Run `terraform init` then `terraform test` in the module directory.

run "defaults_and_sharing" {
  command = plan

  variables {
    tenants = {
      "team-a" = {
        github_team = "team-a"
        aws_accounts = {
          "account-a" = {}
          "account-b" = {
            shared_with_tenants = ["team-b"]
            cloudwatch          = { custom_namespaces = ["ECS/ContainerInsights", "CWAgent"] }
            xray                = { enabled = true }
            amazon_prometheus   = { workspace_id = "ws-bfdd5d7a-5571-4686-bfd4-43ab07cf8d54ba" }
          }
        }
      }
      "team-b" = {}
    }
  }

  assert {
    condition = (
      output.accounts["account-a"].pdc_enabled &&
      output.accounts["account-a"].cloudwatch.enabled &&
      !output.accounts["account-a"].xray.enabled &&
      output.accounts["account-a"].amazon_prometheus == null
    )
    error_message = "An empty account entry should give PDC and CloudWatch only."
  }

  assert {
    condition     = output.accounts["account-b"].amazon_prometheus.region == "eu-west-2"
    error_message = "The Amazon Managed Service for Prometheus region should default to eu-west-2."
  }

  assert {
    condition = (
      jsonencode(output.accounts["account-a"].query_tenants) == jsonencode(["team-a"]) &&
      jsonencode(output.accounts["account-b"].query_tenants) == jsonencode(["team-a", "team-b"])
    )
    error_message = "query_tenants should be the owning tenant followed by the tenants the account is shared with."
  }

  assert {
    condition = (
      jsonencode(output.tenants["team-a"].query_accounts) == jsonencode(["account-a", "account-b"]) &&
      jsonencode(output.tenants["team-b"].query_accounts) == jsonencode(["account-b"]) &&
      output.tenants["team-b"].github_team == null
    )
    error_message = "query_accounts should list a tenant's own accounts and those shared with it."
  }
}

run "account_in_two_tenants" {
  command = plan

  variables {
    tenants = {
      "team-a" = { aws_accounts = { "account-a" = {} } }
      "team-b" = { aws_accounts = { "account-a" = {} } }
    }
  }

  expect_failures = [var.tenants]
}

run "shared_with_unknown_tenant" {
  command = plan

  variables {
    tenants = {
      "team-a" = { aws_accounts = { "account-a" = { shared_with_tenants = ["team-b"] } } }
    }
  }

  expect_failures = [var.tenants]
}

run "comma_separated_namespaces" {
  command = plan

  variables {
    tenants = {
      "team-a" = { aws_accounts = { "account-a" = { cloudwatch = { custom_namespaces = ["CWAgent,ECS/ContainerInsights"] } } } }
    }
  }

  expect_failures = [var.tenants]
}

run "invalid_amazon_prometheus_workspace" {
  command = plan

  variables {
    tenants = {
      "team-a" = { aws_accounts = { "account-a" = { amazon_prometheus = { workspace_id = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-1" } } } }
    }
  }

  expect_failures = [var.tenants]
}
