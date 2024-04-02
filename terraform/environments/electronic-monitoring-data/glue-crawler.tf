resource "aws_vpc_security_group_ingress_rule" "db_glue" {
  security_group_id = aws_security_group.db.id
  description       = "glue"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "db_glue" {
  security_group_id = aws_security_group.db.id
  description       = "glue"
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  referenced_security_group_id = aws_security_group.db.id

}

resource "aws_iam_role" "db_crawler" {
    name = "db-crawler"
    assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
    managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
}

resource "aws_glue_connection" "db_crawler" {
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:sqlserver://${aws_db_instance.database_2022.endpoint}"
    PASSWORD            = aws_secretsmanager_secret_version.db_password.secret_string
    USERNAME            = "admin"
  }

  name = "db_crawler"

  physical_connection_requirements {
    security_group_id_list = [aws_security_group.db.id]
    subnet_id              = data.aws_subnet.private_subnets_a.id
    availability_zone      = data.aws_subnet.private_subnets_a.availability_zone
  }
}

resource "aws_glue_crawler" "db_crawler" {
  database_name = aws_glue_catalog_database.db_crawler.name
  name          = "crawl_all_tables"
  role          = aws_iam_role.db_crawler.arn

  jdbc_target {
    connection_name = aws_glue_connection.db_crawler.name
    path            = "%"
  }
}

resource "aws_glue_trigger" "db_crawler" {
    name          = "crawl_all_tables"
    # Change this to CONDITIONAL to automate
    type          = "ON_DEMAND"
  # Uncomment the below]
    # predicate {
    #     conditions {
    #   some condition here...
    #     }
    actions {
        crawler_name   = aws_glue_crawler.db_crawler.name
    }
}

resource "aws_glue_catalog_database" "db_crawler" {
  name = "all_tables"
}
