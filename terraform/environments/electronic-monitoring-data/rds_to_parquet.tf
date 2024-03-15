resource "aws_glue_crawler" "rds_to_parquet" {
  database_name = aws_glue_catalog_database.rds_to_parquet.name
  name          = "rds_to_parquet"
  role          = aws_iam_role.rds_to_parquet.arn

  jdbc_target {
    connection_name = aws_glue_connection.rds_to_parquet.name
    path            = "test"
  }
}

resource "aws_glue_connection" "rds_to_parquet" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:sqlserver:// ${aws_db_instance.database_2022.address}:${aws_db_instance.database_2022.endpoint};database=${aws_db_instance.database_2022.db_name}"
    PASSWORD            = "examplepassword"
    USERNAME            = "exampleusername"
  }

  name = "rds_to_parquet"

  physical_connection_requirements {
    security_group_id_list = [aws_security_group.db.id]
    subnet_id              = tolist(data.aws_subnets.shared-public.ids)[0]
  }
}

resource "aws_glue_catalog_database" "rds_to_parquet" {
  name = "rds_to_parquet"
}

resource "aws_iam_role" "rds_to_parquet" {
    name = "rds-to-parquet-glue"
    assume_role_policy = aws_iam_policy_document.rds_to_parquet.json
    managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
}

resource "aws_iam_policy_document" "rds_to_parquet" {
    statement {
        sid = "EC2RDSPermissions"
        effect = "allow"
        actions = ["rds:Describe*",
        "rds:ListTagsForResource",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcAttribute",
        "ec2:DescribeVpcs"]
        resources = ["*"]
    }
}