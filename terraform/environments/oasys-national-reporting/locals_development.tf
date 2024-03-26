locals {

  # baseline config
  development_config = {

    # baseline_ec2_instances = {
    #   dev-web-a = merge(local.defaults_web_ec2, 
    #   {
    #     config = merge(local.defaults_web_ec2.config, {
    #       availability_zone = "${local.region}a"        
    #     })
    #     instance = merge(local.defaults_web_ec2.instance, {
    #       instance_type = "t3.large"
    #     })
    #   })
    #   dev-boe-a = merge(local.defaults_boe_ec2, 
    #   {
    #     config = merge(local.defaults_boe_ec2.config, {
    #       availability_zone = "${local.region}a"        
    #     })
    #     instance = merge(local.defaults_boe_ec2.instance, {
    #       instance_type = "t3.large"
    #     })
    #   })
    # }
  }  
}

