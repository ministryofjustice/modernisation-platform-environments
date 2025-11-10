terraform {
  required_version = ">= 1.0.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
}

data "aws_availability_zones" "available" {}

locals {
  name = "test-dms"
  tags = {
    business-unit    = "HMPPS"
    application      = "Data Engineering"
    environment-name = "sandbox"
    is-production    = "False"
    owner            = "DMET"
    team-name        = "DMET"
    namespace        = "dmet-test"
  }
}

module "dms" {
  source = "github.com/ministryofjustice/analytical-platform//terraform/aws/modules/data-engineering/dms?ref=66a7d870"

  environment = local.tags.environment-name
  vpc_id      = module.vpc.vpc_id
  db          = aws_db_instance.dms_test.identifier

  dms_replication_instance = {
    replication_instance_id    = aws_db_instance.dms_test.identifier
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = local.name
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    multi_az                   = false
    replication_instance_class = "dms.t2.micro"
    inbound_cidr               = module.vpc.vpc_cidr_block
  }

  dms_source = {
    engine_name                 = "oracle"
    secrets_manager_arn         = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:dms-user-secret"
    sid                         = aws_db_instance.dms_test.db_name
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-01-29T11:00:00Z"
  }

  replication_task_id = {
    full_load = "${aws_db_instance.dms_test.identifier}-full-load"
    cdc       = "${aws_db_instance.dms_test.identifier}-cdc"
  }

  dms_mapping_rules     = "${path.module}/mappings.json"
  landing_bucket        = aws_s3_bucket.landing.bucket
  landing_bucket_folder = "${local.tags.team-name}/${aws_db_instance.dms_test.identifier}"

  tags = local.tags
}
