module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment = module.environment

  options = {
    enable_application_environment_wildcard_cert = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
  }
}
