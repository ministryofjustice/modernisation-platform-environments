# Random Password / Suffix
resource "random_password" "master_password" {
  count = var.create_redshift_cluster && var.create_random_password ? 1 : 0

  length      = var.random_password_length
  min_lower   = 1
  min_numeric = 1
  min_special = 1
  min_upper   = 1
  special     = false
}

resource "random_string" "unique_suffix" {
  length  = 6
  special = false
}

resource "aws_secretsmanager_secret" "redshift_connection" {
  description = "Redshift connect details"
  name        = "${var.project_id}-redshift-secret-${var.env}"
}

resource "aws_secretsmanager_secret_version" "redshift_connection" {
  secret_id = aws_secretsmanager_secret.redshift_connection.id
  secret_string = jsonencode({
    username            = aws_redshift_cluster.this[0].master_username
    password            = aws_redshift_cluster.this[0].master_password
    engine              = "redshift"
    host                = aws_redshift_cluster.this[0].endpoint
    port                = "5439"
    dbClusterIdentifier = aws_redshift_cluster.this[0].cluster_identifier
  })
}