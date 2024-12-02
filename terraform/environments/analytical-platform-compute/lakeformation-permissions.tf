
resource "aws_lakeformation_lf_tag" "source" {
  count  = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0
  key    = "source"
  values = ["create-a-derived-table"]
}

resource "aws_lakeformation_permissions" "cadet_all_data" {
  for_each = (terraform.workspace == "analytical-platform-compute-production" ?
  toset(["TABLE", "DATABASE"]) : toset([]))

  principal   = module.copy_apdp_cadet_metadata_to_compute_assumable_role.iam_role_arn
  permissions = ["ALL"] # https://docs.aws.amazon.com/lake-formation/latest/dg/lf-permissions-reference.html

  lf_tag_policy {
    resource_type = each.value
    expression {
      key    = "source"
      values = ["create-a-derived-table"]
    }
  }
}

resource "aws_lakeformation_lf_tag" "domain" {
  for_each = try(local.environment_configuration.cadet_lf_tags, {})
  key = each.key
  values = each.value
}

resource "aws_lakeformation_permissions" "cadet_domain_database_data" {
  for_each = try(local.environment_configuration.cadet_lf_tags, {})

  principal   = module.copy_apdp_cadet_metadata_to_compute_assumable_role.iam_role_arn
  permissions = ["ALL"] # https://docs.aws.amazon.com/lake-formation/latest/dg/lf-permissions-reference.html

  lf_tag_policy {
    resource_type = "DATABASE"
    expression {
      key    = "domain"
      values = each.value
    }
  }
}

resource "aws_lakeformation_permissions" "cadet_domain_table_data" {
  for_each = try(local.environment_configuration.cadet_lf_tags, {})

  principal   = module.copy_apdp_cadet_metadata_to_compute_assumable_role.iam_role_arn
  permissions = ["ALL"] # https://docs.aws.amazon.com/lake-formation/latest/dg/lf-permissions-reference.html

  lf_tag_policy {
    resource_type = "TABLE"
    expression {
      key    = "domain"
      values = each.value
    }
  }
}

import {
  for_each = try(local.environment_configuration.cadet_lf_tags, {})
  to = aws_lakeformation_lf_tag.domain[each.key]
  id = "${local.environment_management.account_ids[terraform.workspace]}:${each.key}"
}
