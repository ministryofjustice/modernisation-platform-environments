# This file is pretty much the same as secretsmanager.tf, to make it easy to switch
# between SSM parameters and SecretManager Secrets
# Use Secrets if you need to share a parameter across accounts.

locals {
  ssm_parameters_list = flatten([
    for sp_key, sp_value in var.ssm_parameters : [
      for param_name, param_value in sp_value.parameters : {
        key = "${sp_value.prefix}${sp_key}${sp_value.postfix}${param_name}"
        value = merge(param_value,
          param_value.kms_key_id == null ? { kms_key_id = sp_value.kms_key_id } : {}
        )
      }
    ]
  ])

  ssm_random_passwords = {
    for item in local.ssm_parameters_list :
    item.key => item.value.random if item.value.random != null
  }

  ssm_uuid = {
    for item in local.ssm_parameters_list :
    item.key => item.value.uuid if item.value.uuid
  }

  ssm_parameters_value = {
    for item in local.ssm_parameters_list :
    item.key => item.value if item.value.value != null
  }

  # use s3 bucket name as value, lookup from module
  ssm_parameters_value_s3_bucket_name = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = module.s3_bucket[item.value.value_s3_bucket_name].bucket.bucket
    }) if item.value.value_s3_bucket_name != null
  }

  ssm_parameters_random = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = random_password.this[item.key].result
    }) if item.value.random != null
  }

  ssm_parameters_uuid = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = random_uuid.ssm[item.key].result
    }) if item.value.uuid
  }

  ssm_parameters_file = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = file(item.value.file)
    }) if item.value.file != null
  }

  ssm_parameters_default = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = "placeholder, overwrite me outside of terraform"
    }) if item.value.value == null && item.value.value_s3_bucket_name == null && item.value.random == null && item.value.uuid == false && item.value.file == null
  }
}

resource "aws_ssm_association" "this" {
  for_each = var.ssm_associations

  apply_only_at_cron_interval = each.value.apply_only_at_cron_interval
  association_name            = each.key
  name                        = try(aws_ssm_document.this[each.value.name].name, each.value.name) # so ssm_doc is created first
  max_concurrency             = each.value.max_concurrency
  max_errors                  = each.value.max_errors
  schedule_expression         = each.value.schedule_expression

  dynamic "output_location" {
    for_each = each.value.output_location != null ? [each.value.output_location] : []
    content {
      s3_bucket_name = try(module.s3_bucket[output_location.value.s3_bucket_name].bucket.bucket, output_location.value.s3_bucket_name)
      s3_key_prefix  = output_location.value.s3_key_prefix
      s3_region      = var.environment.region
    }
  }

  dynamic "targets" {
    for_each = each.value.targets
    content {
      key = targets.value.key
      values = [
        for value in targets.value.values : try(module.ec2_instance[value].aws_instance.id, value)
      ]
    }
  }
}

resource "aws_ssm_document" "this" {
  for_each = var.ssm_documents

  name            = each.key
  document_type   = each.value.document_type
  document_format = each.value.document_format
  content         = each.value.content

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "random_password" "this" {
  for_each = local.ssm_random_passwords

  length  = each.value.length
  special = each.value.special
}

resource "random_uuid" "ssm" {
  for_each = local.ssm_uuid
}

resource "aws_ssm_parameter" "fixed" {
  #checkov:skip=CKV_AWS_337:Ensure SSM parameters are using KMS CMK; default is now to use general business unit key
  #checkov:skip=CKV2_AWS_34:AWS SSM Parameter should be Encrypted; default is SecureString but some resources don't support this, e.g. cloud watch agent

  for_each = merge(
    local.ssm_parameters_value,
    local.ssm_parameters_value_s3_bucket_name,
    local.ssm_parameters_random,
    local.ssm_parameters_uuid,
    local.ssm_parameters_file
  )

  name        = each.key
  description = each.value.description
  type        = each.value.type
  key_id      = each.value.type == "SecureString" && each.value.kms_key_id != null ? try(var.environment.kms_keys[each.value.kms_key_id].arn, each.value.kms_key_id) : null
  value       = each.value.value
  tier        = each.value.tier

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_ssm_parameter" "placeholder" {
  #checkov:skip=CKV_AWS_337:Ensure SSM parameters are using KMS CMK; default is now to use general business unit key
  #checkov:skip=CKV2_AWS_34:AWS SSM Parameter should be Encrypted; default is SecureString but some resources don't support this, e.g. cloud watch agent

  for_each = local.ssm_parameters_default

  name        = each.key
  description = each.value.description
  type        = each.value.type
  key_id      = each.value.type == "SecureString" && each.value.kms_key_id != null ? try(var.environment.kms_keys[each.value.kms_key_id].arn, each.value.kms_key_id) : null
  value       = each.value.value

  tags = merge(local.tags, {
    Name = each.key
  })

  lifecycle {
    ignore_changes = [value]
  }
}
