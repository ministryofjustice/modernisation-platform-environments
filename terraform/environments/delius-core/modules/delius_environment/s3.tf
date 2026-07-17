# S3 bucket for hosting the terraform state of the Weblogic ECS config: https://github.com/ministryofjustice/delius-releases
module "weblogic_ecs_remote_state" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399" # v9.0.0

  bucket_name        = "${var.account_info.application_name}-${var.env_name}-weblogic-ecs-remote-state"
  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}