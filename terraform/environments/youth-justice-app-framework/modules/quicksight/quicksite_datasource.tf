resource "aws_quicksight_data_source" "redshift" {
  data_source_id = "Redshift"
  name           = "Redshift"

  parameters {
    redshift {
        host = var.redshift_host
        port = var.redshift_port
        database   = "yjb_returns"
    }
    disable_ssl = false

    vpc_connection_arn = aws_quicksight_vpc_connection.local.arn
  }

  type = "redshift"

  
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
  data_source_id = "prosgresql"
  name           = "YJB_CASE_REPORTING_PROD"

  parameters {
    aurora_postgresql {
        host = var.postgres_host
        port = var.postgreport_port
        database   = "yjaf"
    }
    disable_ssl = false

    vpc_connection_arn = aws_quicksight_vpc_connection.local.arn
  }

  type = "POSTGRESQL"

  
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