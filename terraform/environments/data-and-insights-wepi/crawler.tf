resource "aws_glue_catalog_database" "mojap_all_tables" {
  name        = "ap-mojap-tables-all"
  description = ""
}

resource "aws_glue_catalog_database" "sop_redshift" {
  name        = "sop-redshift"
  description = ""
}

resource "aws_glue_crawler" "mojap_import_all" {
  #checkov:skip=CKV_AWS_195
  database_name = aws_glue_catalog_database.mojap_all_tables.name
  name          = "sop-import-all"
  role          = aws_iam_role.wepi_iam_role_glue.arn
  description   = "Identifies schema for SOP datasets on AP"
  s3_target {
    path            = "s3://mojap-mp-redshift/"
    connection_name = aws_glue_connection.wepi_glue_conn_redshift.name
  }
}

resource "aws_glue_crawler" "absence_crawler" {
  #checkov:skip=CKV_AWS_195
  database_name = aws_glue_catalog_database.sop_redshift.name
  name          = "absence-redshift-schema"
  role          = aws_iam_role.wepi_iam_role_glue.arn
  description   = "Crawl AWS Redshift \"absence\" table using JDBC"
  jdbc_target {
    path            = "wepidevelopmentdb/public/absence"
    connection_name = aws_glue_connection.wepi_glue_conn_redshift.name
  }
}

resource "aws_glue_crawler" "leavers_crawler" {
  #checkov:skip=CKV_AWS_195
  database_name = aws_glue_catalog_database.sop_redshift.name
  name          = "leavers-redshift-schema"
  role          = aws_iam_role.wepi_iam_role_glue.arn
  description   = "Crawl AWS Redshift \"leavers\" table using JDBC"
  jdbc_target {
    path            = "wepidevelopmentdb/public/leavers"
    connection_name = aws_glue_connection.wepi_glue_conn_redshift.name
  }
}

# resource "null_resource" "setup_leavers_redshift" {
#   depends_on = ["aws_redshift_cluster"] #wait for the db to be ready
#   provisioner "local-exec" {
#     command = "mysql -u ${aws_redshift_cluster.wepi_redshift_cluster.master_username} -p${aws_secretsmanager_secret_version.wepi_redshift_admin_pw.secret_string} < create_table_leavers.sql"
#   }
# }

