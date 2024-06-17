#------------------------------------------------------------------------------
# SSM Agent - update Systems Manager Agent
#------------------------------------------------------------------------------

#resource "aws_ssm_association" "update_ssm_agent" {
#  name             = "AWS-UpdateSSMAgent" # this is an AWS provided document
#  association_name = "update-ssm-agent"
#  parameters = {
#    allowDowngrade = "false"
#  }
#  targets {
#    # we could just target all instances, but this would also include the bastion, which gets rebuilt everyday
#    key    = "tag:os_type"
#    values = ["Linux", "Windows"]
#  }
#  apply_only_at_cron_interval = false
#  schedule_expression         = "cron(30 7 ? * TUE *)"
#}

