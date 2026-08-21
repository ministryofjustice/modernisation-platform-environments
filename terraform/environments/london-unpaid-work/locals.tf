#### This file can be used to store locals specific to the member account ####
locals {
  baseline_presets_all_environments = {
    options = {
      enable_ec2_cloud_watch_agent                = true
      enable_ec2_oracle_enterprise_managed_server = true
      enable_ec2_security_groups                  = true
      enable_ec2_self_provision                   = true
      enable_ec2_session_manager_cloudwatch_logs  = true
      enable_ec2_ssm_agent_update                 = true
      enable_ec2_user_keypair                     = true
      enable_image_builder                        = true
      enable_s3_bucket                            = true
      enable_ssm_command_monitoring               = true
      s3_iam_policies = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }
}
