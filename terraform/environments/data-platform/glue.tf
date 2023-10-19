# creates database and tables in the glue catalogue for data as a product logs.
# Meaning logs are queryable via Athena.
resource "aws_glue_catalog_database" "data_product_logs" {
  name   = "daap_logs"
}

resource "aws_glue_catalog_table" "lambdas" {
  name          = "lambdas"
  database_name = aws_glue_catalog_database.data_product_logs.name
  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    comment               = "table for logs from the python daap lambda functions"

  }

  storage_descriptor {
    location      = "s3://${module.logs_s3_bucket.bucket.id}/logs/json/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "lambda_name"
      type = "string"
    }
    columns {
      name = "data_product_name"
      type = "string"
    }
    columns {
      name = "table_name"
      type = "string"
    }
    columns {
      name = "date_time"
      type = "string"
    }
    columns {
      name = "function_name"
      type = "string"
    }
    columns {
      name = "image_version"
      type = "string"
    }
    columns {
      name = "base_image_version"
      type = "string"
    }
    columns {
      name = "level"
      type = "string"
    }
    columns {
      name = "message"
      type = "string"
    }
  }

}


resource "aws_glue_catalog_table" "s3_objects" {
  name          = "s3_objects"
  database_name = aws_glue_catalog_database.data_product_logs.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    classification        = "cloudtrail"
    comment               = "CloudTrail table for logs from the data and landing data buckets"

  }

  storage_descriptor {
    location      = "s3://${module.logs_s3_bucket.bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail/"
    input_format  = "com.amazon.emr.cloudtrail.CloudTrailInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      parameters = {
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hive.hcatalog.data.JsonSerDe"
    }

    columns {
      name = "eventversion"
      type = "string"
    }
    columns {
      name = "useridentity"
      type = "struct<type:string,principalid:string,arn:string,accountid:string,invokedby:string,accesskeyid:string,username:string,sessioncontext:struct<attributes:struct<mfaauthenticated:string,creationdate:string>,sessionissuer:struct<type:string,principalid:string,arn:string,accountid:string,username:string>,ec2roledelivery:string,webidfederationdata:map<string,string>>>"
    }
    columns {
      name = "eventtime"
      type = "string"
    }
    columns {
      name = "eventsource"
      type = "string"
    }
    columns {
      name = "eventname"
      type = "string"
    }
    columns {
      name = "awsregion"
      type = "string"
    }
    columns {
      name = "sourceipaddress"
      type = "string"
    }
    columns {
      name = "useragent"
      type = "string"
    }
    columns {
      name = "errorcode"
      type = "string"
    }
    columns {
      name = "errormessage"
      type = "string"
    }
    columns {
      name = "requestparameters"
      type = "string"
    }
    columns {
      name = "responseelements"
      type = "string"
    }
    columns {
      name = "additionaleventdata"
      type = "string"
    }
    columns {
      name = "requestid"
      type = "string"
    }
    columns {
      name = "eventid"
      type = "string"
    }
    columns {
      name = "resources"
      type = "array<struct<arn:string,accountId:string,type:string>>"
    }
    columns {
      name = "eventtype"
      type = "string"
    }
    columns {
      name = "apiversion"
      type = "string"
    }
    columns {
      name = "readonly"
      type = "string"
    }
    columns {
      name = "recipientaccountid"
      type = "string"
    }
    columns {
      name = "serviceeventdetails"
      type = "string"
    }
    columns {
      name = "sharedeventid"
      type = "string"
    }
    columns {
      name = "vpcendpointid"
      type = "string"
    }

  }
}
