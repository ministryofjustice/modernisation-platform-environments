data "aws_caller_identity" "current" {}

resource "aws_quicksight_data_source" "redshift" {
  data_source_id = "Redshift"
  name           = "Redshift"

  parameters {
    redshift {
      host     = var.redshift_host
      port     = var.redshift_port
      database = "yjb_returns"
    }
  }
  ssl_properties {
    disable_ssl = false
  }

  vpc_connection_properties {
    vpc_connection_arn = aws_quicksight_vpc_connection.local.arn
  }

  type = "REDSHIFT"

  credentials {
    secret_arn = var.redshift_quicksight_user_secret_arn
  }

  permission {
    principal = "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:user/default/quicksight-admin-access/${var.quicksight_admin_user}"
    actions = [
      "quicksight:PassDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSourcePermissions",
      "quicksight:DescribeDataSource",
      "quicksight:DeleteDataSource"
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.kms]
}

/*
        "DataSourceParameters": {
            "RedshiftParameters": {
                "Host": "yjbservices.066012302209.eu-west-2.redshift-serverless.amazonaws.com",
                "Port": 5439,
                "Database": "yjb_returns"
            }
        },
        "VpcConnectionProperties": {
            "VpcConnectionArn": "arn:aws:quicksight:eu-west-2:066012302209:vpcConnection/a43aa62f-bb85-48eb-8e7c-17c4504c8281"
        },
        "SslProperties": {
            "DisableSsl": false
        }

*/

resource "aws_quicksight_data_source" "postgresql" {
  data_source_id = "postgresql"
  name           = "YJB_CASE_REPORTING_PROD"

  parameters {
    aurora_postgresql {
      host     = var.postgres_host
      port     = var.postgres_port
      database = "yjaf"
    }
  }

  ssl_properties {
    disable_ssl = false
  }

  vpc_connection_properties {
    vpc_connection_arn = aws_quicksight_vpc_connection.local.arn
  }

  type = "AURORA_POSTGRESQL"

  credentials {
    secret_arn = var.postgres_quicksight_user_secret_arn
  }

  permission {
    principal = "arn:aws:quicksight:eu-west-2:${data.aws_caller_identity.current.account_id}:user/default/quicksight-admin-access/${var.quicksight_admin_user}"
    actions = [
      "quicksight:PassDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSourcePermissions",
      "quicksight:DescribeDataSource",
      "quicksight:DeleteDataSource"
    ]
  }



  depends_on = [aws_iam_role_policy_attachment.kms]

}

/*
        "Name": "YJB_CASE_REPORTING_PROD",
        "Type": "POSTGRESQL",
        "Status": "CREATION_SUCCESSFUL",
        "CreatedTime": "2023-08-24T10:04:49.580000+01:00",
        "LastUpdatedTime": "2023-08-24T10:04:49.580000+01:00",
        "DataSourceParameters": {
            "PostgreSqlParameters": {
                "Host": "yjafrds01-cluster.cluster-cjeb1pcmafeu.eu-west-2.rds.amazonaws.com",
                "Port": 5432,
                "Database": "yjaf"
            }
        },
        "VpcConnectionProperties": {
            "VpcConnectionArn": "arn:aws:quicksight:eu-west-2:066012302209:vpcConnection/a43aa62f-bb85-48eb-8e7c-17c4504c8281"
        },
        "SslProperties": {
            "DisableSsl": false
        }
    },

*/