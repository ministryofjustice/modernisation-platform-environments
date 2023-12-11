#-----------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

resource "aws_db_instance" "database" {
	allocated_storage 									= local.app_data.accounts[local.environment].db_allocated_storage
	storage_type 												= "gp2"
	engine 															= "sqlserver-web"
	engine_version 											= "14.00.3381.3.v1"
	instance_class 											= local.app_data.accounts[local.environment].db_instance_class
	identifier													= local.app_data.accounts[local.environment].db_instance_identifier
	username														= local.app_data.accounts[local.environment].db_user
	password 														= data.aws_secretsmanager_secret_version.db_password.secret_string

}

resource "aws_db_instance_role_association" "rds_s3_role_association" {
	db_instance_identifier 	= aws_db_instance.database.identifier
	feature_name 						= "S3_INTEGRATION"
	role_arn               = "arn:aws:iam::613903586696:role/RDS-S3-CrossAccountAccess"
}

resource "aws_security_group" "db" {
	name 				= "db"
	description = "Allow DB inbound traffic"
	
	ingress {
		from_port 	= 1433
		to_port 		= 1433
		protocol  	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_policy" "rds-s3_access_policy" {
	name = "RDS-S3-Access-Policy"
	description = "Allows mod platform RDS access to tp-dbbackups bucket"

	policy = jsonencode({
		Version = "2012-10-17",
		Statement = [
			{
				Effect = "Allow",
				Action = [
					"s3:GetObject",
					"s3:ListBucket"
				],
				Resource = [
					"arn:aws:s3:::tp-dbbackups/*",
					"arn:aws:s3:::tp-dbbackups"
				]
			}
		]
	})
}

resource "aws_iam_role+policy_attachment" "rds_s3_access_attach" {
	role = aws_iam_role.rds_s3_access.name
	policy_arn = aws_iam_policy.rds_s3_access_policy.arn
}

resource "aws_iam_role" "rds_s3_access" {
	assume_role_policy = jsonencode({
		Version 	= "2012-10-17",
		Statement = [
			{
				Effect = "Allow",
				Principal = {
					Service = "rds.amazonaws.com"
				},
				Action = "sts:AssumeRole",
			},
			{
				Effect = "Allow",
				Principal = {
					AWS = "arn:aws:iam::513884314856:root"
				},
				Action = "sts:AssumeRole"
			}
		]
	})
}

data "aws_secretsmanager_secret" "db_password" {
  name = aws_secretsmanager_secret.chaps_secret.name
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

#------------------------------------------------------------------------------
# KMS setup for RDS
#------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description         = "Encryption key for rds"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.rds-kms.json
}

resource "aws_kms_alias" "rds-kms-alias" {
  name          = "alias/rds"
  target_key_id = aws_kms_key.rds.arn
}

data "aws_iam_policy_document" "rds-kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

