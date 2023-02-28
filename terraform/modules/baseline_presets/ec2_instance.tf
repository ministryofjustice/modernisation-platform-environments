locals {

  ec2_instance = {

    config = {

      # example configuration (assumes image builder, business unit kms cmks and
      # cloud watch agent policies have been created)
      default = {
        availability_zone             = "eu-west-2a"
        subnet_name                   = "private"
        ebs_volumes_copy_all_from_ami = true
        user_data_raw                 = null
        ssm_parameters_prefix         = "ec2/"
        iam_resource_names_prefix     = "ec2-instance"
        instance_profile_policies = [
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "EC2S3BucketWriteAndDeleteAccessPolicy",
          "BusinessUnitKmsCmkPolicy",
          "CloudWatchAgentServerReducedPolicy"
        ]
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
