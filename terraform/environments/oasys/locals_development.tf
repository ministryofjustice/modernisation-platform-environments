locals {

  delius_oasys_queues_development = {
    "dev" = {
      ip_allow_list = flatten([
        module.ip_addresses.mp_cidrs.non_live_eu_west_nat,
        module.ip_addresses.moj_cidr.moj_aws_digital_macos_globalprotect_alpha,
        # Capita ranges
        "85.115.52.180/32",
        "85.115.52.200/29",
        "85.115.53.180/32",
        "85.115.53.200/29",
        "85.115.54.180/32",
        "85.115.54.200/29",
        "82.203.33.128/28",
        "82.203.33.112/28",
        "172.167.141.40/32",
        "51.104.16.30/31",
      ])
    }
  }

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
      db_backup_object_lock_days                 = 3
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_instances = {
      dev-capita-c = {
        config = {
          ami_name          = "base_ol_8_5_2023-06-08T09-45-10.579Z"
          availability_zone = "eu-west-2c"
          instance_profile_policies = [
            # "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # now included automatically by module
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy",
            "Ec2DeliusIntegrationPolicy",
          ]
          subnet_name = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          metadata_options_http_tokens = "optional"
          vpc_security_group_ids       = ["ec2-linux"]
          tags = {
            backup-plan = "daily-and-weekly"
          }
        }
        user_data_cloud_init = {
          args = {
            branch       = "main"
            ansible_args = ""
          }
          scripts = [ # paths are relative to templates/ dir
            "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
            "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
            "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
          ]
        }
        tags = {
          backup           = "false" # opt out of mod platform default backup plan
          component        = "data"
          description      = "Capita dev server"
          os-type          = "Linux"
          os-major-version = 8
          os-version       = "OL 8.5"
          server-type      = "base-ol85"
          update-ssm-agent = "patchgroup1"
        }
      }
    }

  }
}
