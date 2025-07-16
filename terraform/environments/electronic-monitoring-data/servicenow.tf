locals {
  servicenow_credentials_placeholder = {"USERNAME":"placeholder", "PASSWORD": "placeholders"}
}

resource "aws_secretsmanager_secret" "servicenow_credentials" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "credentials/servicenow"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "servicenow_credentials" {
  secret_id     = aws_secretsmanager_secret.servicenow_credentials.id
  secret_string = jsonencode(local.servicenow_credentials_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.servicenow_credentials]
}


data "aws_iam_policy_document" "glue_connection_snow" {
    statement {
        effect = "Allow"
        actions = ["secretsmanager:*"]
        resources = [
            "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:credentials/servicenow*"
        ]
    }
    statement {
      effect = "Allow"
      actions = ["glue:*"]
      resources = [
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:schema/*",
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*",
        "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*"
      ]
    }
    statement {
      effect = "Allow"
      actions = ["s3:*"]
      resources = [
        "arn:aws:s3:::emds-test-cadt/zero-etl/servicenow_test/*"
      ]
    }
    statement {
      effect = "Allow"
      actions = ["cloudwatch:PutMetricData"]
      resource = ["*"]
      condition {
        test     = "StringEquals"
        values   = ["AWS/Glue/ZeroETL"]
        variable = "cloudwatch:namespace"
      }
    }
    statement {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resource = ["*"]
    }
}

resource "aws_iam_policy" "glue_connection_snow_access" {
    name = "glue_connection_snow_access"
    policy = data.aws_iam_policy_document.glue_connection_snow.json
}

resource "aws_iam_role" "glue_connection_snow_access" {
    name = "glue_connection_snow_access"
    assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_role_policy_attachment" "glue_connection_snow_access" {
    role = aws_iam_role.glue_connection_snow_access.name
    policy_arn = aws_iam_policy.glue_connection_snow_access.arn
}

# resource "aws_glue_connection" "servicenow" {
#   name            = "servicenow-connector"
#   connection_type = "SERVICENOW"
#   connection_properties = {
#     SECRET_ID = "net.snowflake.client.jdbc.SnowflakeDriver"
#     CONNECTION_TYPE      = "Jdbc"
#     CONNECTOR_URL        = "s3://example/snowflake-jdbc.jar" # S3 path to the snowflake jdbc jar
#     JDBC_CONNECTION_URL  = "[[\"default=jdbc❄//example.com/?user=$${user}&password=$${password}\"],\",\"]"
#   }
# }
