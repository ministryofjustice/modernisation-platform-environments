locals {

  ec2_instance = {

    profile_policies = {

      # remember to add the appropriate S3 policy to this
      default = flatten([
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        local.iam_policies_ec2_default,
      ])
    }

    config = {

      # example configuration
      default = {
        availability_zone             = "eu-west-2a"
        subnet_name                   = "private"
        ebs_volumes_copy_all_from_ami = true
        user_data_raw                 = null
        ssm_parameters_prefix         = "ec2/"
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = flatten([
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          local.iam_policies_ec2_default,
          "EC2S3BucketWriteAndDeleteAccessPolicy",
        ])
      }

      db = {
        availability_zone             = "eu-west-2a"
        subnet_name                   = "data"
        ebs_volumes_copy_all_from_ami = true
        user_data_raw                 = null
        ssm_parameters_prefix         = "database/"
        iam_resource_names_prefix     = "ec2-database"
        instance_profile_policies = flatten([
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          local.iam_policies_ec2_default,
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "Ec2AccessSharedS3Policy",
        ])
      }
    }

    instance = {

      # assumes there is a 'private' security group created
      default = {
        disable_api_termination      = false
        instance_type                = "t3.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "required"
        monitoring                   = false
        vpc_security_group_ids       = ["private"]
      }

      default_rhel6 = {
        disable_api_termination      = false
        instance_type                = "t2.medium"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional"
        monitoring                   = false
        vpc_security_group_ids       = ["private"]
      }
      # assumes there is a 'data' security group created
      default_db = {
        disable_api_termination      = false
        instance_type                = "r6i.xlarge"
        key_name                     = "ec2-user"
        metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
        monitoring                   = true
        vpc_security_group_ids       = ["data"]
      }
    }

    user_data_cloud_init = {

      ansible = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }

      ssm_agent_and_ansible = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = "--tags ec2provision"
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }

      ssm_agent_ansible_no_tags = {
        args = {
          lifecycle_hook_name  = "ready-hook"
          branch               = "main"
          ansible_repo         = "modernisation-platform-configuration-management"
          ansible_repo_basedir = "ansible"
          ansible_args         = ""
        }
        scripts = [
          "install-ssm-agent.sh.tftpl",
          "ansible-ec2provision.sh.tftpl",
          "post-ec2provision.sh.tftpl"
        ]
      }
    }

    route53_records = {
      internal_only = {
        create_internal_record = true
        create_external_record = false
      }

      internal_and_external = {
        create_internal_record = true
        create_external_record = true
      }
    }
  }
}
