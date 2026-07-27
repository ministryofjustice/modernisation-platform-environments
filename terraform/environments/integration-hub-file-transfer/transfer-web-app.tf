data "aws_ssoadmin_instances" "this" {
  provider = aws.sso-readonly
}

data "aws_identitystore_group" "this" {
  for_each          = local.transfer_iam_identity_center_groups
  provider          = aws.sso-readonly
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.key
    }
  }
}

resource "aws_transfer_web_app" "this" {
  identity_provider_details {
    identity_center_config {
      instance_arn = one(data.aws_ssoadmin_instances.this.arns)
      role         = module.iam_role_transfer_web_app.arn
    }
  }
  web_app_units {
    provisioned = 1
  }
}

resource "aws_s3control_access_grants_instance" "this" {
  identity_center_arn = one(data.aws_ssoadmin_instances.this.arns)
}

resource "aws_s3control_access_grants_location" "incoming" {
  depends_on = [aws_s3control_access_grants_instance.this]

  iam_role_arn   = module.iam_role_s3_access_grants_location.arn
  location_scope = "s3://${module.s3_bucket["incoming"].s3_bucket_id}"
}

resource "aws_s3control_access_grant" "incoming_uploaders" {
  for_each = data.aws_identitystore_group.this

  access_grants_location_id = aws_s3control_access_grants_location.incoming.access_grants_location_id
  permission                = "READWRITE"

  access_grants_location_configuration {
    s3_sub_prefix = "group/${each.key}/*"
  }

  grantee {
    grantee_type       = "DIRECTORY_GROUP"
    grantee_identifier = each.value.group_id
  }
}
