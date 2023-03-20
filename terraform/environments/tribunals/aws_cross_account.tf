provider "aws" {
  region     = "eu-west-1"
  access_key = jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["dms_source_account_access_key"]
  secret_key = jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["dms_source_account_secret_key"]
  alias      = "mojdsd"
}

resource "aws_security_group" "dms_access_rule" {
  name        = "mp_dms_access_rule_tribunals"
  description = "allow dms access to the database from modernisatoon platform"

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    description = "Allow DMS to connect to source database"
    cidr_blocks = [module.dms.dms_replication_instance]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  provider = aws.mojdsd

}

resource "null_resource" "setup_source_ec2_security_group" {
  depends_on = [module.dms.dms_replication_instance]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "ifconfig -a; chmod +x ./setup-security-group.sh; ./setup-security-group.sh"

    environment = {
      DMS_SECURITY_GROUP            = aws_security_group.dms_access_rule.id
      EC2_INSTANCE_ID               = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["ec2-instance-id"])
      DMS_SOURCE_ACCOUNT_ACCESS_KEY = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["dms_source_account_access_key"])
      DMS_SOURCE_ACCOUNT_SECRET_KEY = nonsensitive(jsondecode(data.aws_secretsmanager_secret_version.source-db.secret_string)["dms_source_account_secret_key"])
      AWS_REGION                    = "eu-west-1"

    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}