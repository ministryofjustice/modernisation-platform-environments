#Internal
# trivy:ignore:AVD-AWS-0052 reason: (HIGH): Todo - we only want to allow in remote_domain. post migration task to only allow in that
module "alb" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/alb/aws"
  version = "10.2.0"

  name               = "${var.alb_name}-${local.alb_suffix}"
  internal           = var.internal
  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.alb_subnets_ids

  enable_deletion_protection = false

  create_security_group = false
  security_groups       = [module.alb_sg.security_group_id]
  associate_web_acl     = var.associate_web_acl
  web_acl_arn           = var.web_acl_arn

  idle_timeout               = 240
  drop_invalid_header_fields = false
  access_logs                = local.access_logs

  tags = local.all_tags
}

module "log_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "${var.project_name}-${var.environment}-${var.alb_name}-${local.alb_suffix}-logs"
  acl    = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = false #todo probably should be true but matching yjaf atm
  attach_require_latest_tls_policy      = false #todo same here
  #todo cloudtrail dataevents for this bucket required
  tags = local.all_tags
}


module "alb_sg" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "${var.alb_name}-${local.alb_suffix}-lb-security-group"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = var.alb_ingress_with_source_security_group_id_rules
  ingress_with_cidr_blocks                       = var.alb_ingress_with_cidr_blocks_rules


  number_of_computed_ingress_with_source_security_group_id = var.count_alb_ingress_with_source_security_group_id_rules

  egress_rules = ["all-all"]

  tags = local.all_tags
}
