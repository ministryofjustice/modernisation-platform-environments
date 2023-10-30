locals {
  web_ec2 = {
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_owner                     = "self"
      ebs_volumes_copy_all_from_ami = false
    })
    instance = merge(module.baseline_presets.ec2_instance.instance.default, {
      disable_api_termination = true
      monitoring              = true
      vpc_security_group_ids  = ["domain", "web", "jumpserver"]
      tags = {
        backup-plan         = "daily-and-weekly"
        instance-scheduling = "skip-scheduling"
      }
    })
    ebs_volumes = {
      "/dev/sdb"  = { label = "app" }
    }
    tags = {
      os-type   = "Windows"
      component = "web"
    }
    route53_records = module.baseline_presets.ec2_instance.route53_records.internal_and_external
  }
}