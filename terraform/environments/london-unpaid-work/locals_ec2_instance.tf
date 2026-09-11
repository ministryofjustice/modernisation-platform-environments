locals {
  ec2_instances = {

    web = {
      config = {
        ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
        iam_resource_names_prefix = "ec2-weblogic"
        instance_profile_policies = [
          # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
          "EC2Default",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
        ]
        subnet_name = "private"
      }
      instance = {
        disable_api_termination      = false
        instance_type                = "t2.small"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional"
        vpc_security_group_ids       = ["private-web"]
      }
    #   route53_records = {
    #     create_internal_record = true
    #     create_external_record = true
    #   }
    #   user_data_cloud_init = {
    #     args = {
    #       branch       = "main"
    #       ansible_args = "--tags ec2provision"
    #     }
    #     scripts = [ # paths are relative to templates/ dir
    #       "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
    #       "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
    #       "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
        # ]
    #   }
      tags = {
        ami                    = "nomis_rhel_6_10_weblogic_appserver_10_3"
        backup                 = "false" # disable mod platform backup since everything is in code
        component              = "web"
        description            = "london-unpaid-work web instance"
        instance-access-policy = "limited"
        # os-type                = "Linux"
        # server-type            = "nomis-web"
        #update-ssm-agent      = "patchgroup1" # not supported on RHEL6, don't include
      }
    }
  }
}